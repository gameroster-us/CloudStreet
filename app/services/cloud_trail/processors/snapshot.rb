class CloudTrail::Processors::Snapshot
  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args)
    service_type = args[0]["service_type"]
    group_events = args[0]["group_events"]
    group_events.each do |event|
      obj = new(adapter, region_code_map[event["region_code"]], event["event_data"], service_type, event['event_name'])
      obj.extend "CloudTrail::Events::Snapshot::#{event['event_name']}".constantize
      yield(obj)
    end
  end

  def initialize(adapter, region, *args)
    @adapter = adapter
    @region = region
    @events = args[0]
    @service_type = args[1]
    @event_name = args[2]
  end

  def get_event_attributes_for_vol_snap
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["responseElements"]["snapshotId"])
      end
      response
    end
  end

  def get_event_attributes_for_rds_snap
    parse_events_data = parse_events([]) do |response, event_attributes, event|
      unless event_attributes.blank?
        response << event_attributes.merge("provider_id" => event["responseElements"]["dBSnapshotIdentifier"])
      end
      response
    end
  end

  def attributes_for_snapshots(parsed_data)
    status = :success
    event_ids = parsed_data.map { |e| e["eventID"] }
    resource_names = parsed_data.map { |e| e["provider_id"] }
    filters = generate_filters(resource_names, event_name)
    snapshot_objs = fetch_remote_services(filters)
    snapshot_objs = snapshot_objs.select { |d| resource_names.include?(d.provider_id) }
    filters = { adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id,
      provider_id:  snapshot_objs.map(&:provider_id) }
    existing_snaps_provider_ids = Snapshots::AWS.where(filters).pluck(:provider_id)

    unless snapshot_objs.nil?
      result = []
      existing_snap_result = []
      common_filters = { adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account.id }
      existing_services_map = Service.where(common_filters).where(state:['running', 'stopped'], type: ["Services::Compute::Server::Volume::AWS", "Services::Database::Rds::AWS"]).pluck(:provider_data, :id).to_h
      snapshot_objs.each do |snap_obj|
        if existing_snaps_provider_ids.include? snap_obj.provider_id
          snap = Snapshots::AWS.where(common_filters).where(provider_id: snap_obj.provider_id).first
          if snap.category.eql? 'volume'
            snap.service_id = existing_services_map[snap.provider_data["volume_id"]]
          else
            snap.service_id = existing_services_map[snap.provider_data["instance_id"]]
          end
          existing_snap_result << snap
          next
        end

        current_filters = common_filters.dup
        current_filters.merge!({ provider_id: snap_obj.provider_id })
        service = Snapshots::AWS.new(snap_obj.get_attributes_for_service_table.merge!(current_filters))
        #service.cost_by_hour = service.calculate_hourly_cost(@adapter).to_d
        #service.last_cost_update_time = Time.now
        if service.category.eql? 'volume'
          service.service_id = existing_services_map[service.provider_data["volume_id"]]
        else
          service.service_id = existing_services_map[service.provider_data["instance_id"]]
        end
        result << service
      end
      # Fixed N+1 query for bulk import.
      Snapshot.import result
      Snapshot.import existing_snap_result, on_duplicate_key_update: { conflict_target: [:id], columns: [:service_id] }
    end
  rescue StandardError => e
    status = :failure
    CTLog.error e
    CTLog.error e.backtrace
  ensure
    self.class.update_cloud_trail_event_status(@adapter.id, event_ids, status)
  end

  def modify_snapshot(snapshot_id, permission)
    permission.eql?("public") ? update_snapshot_attribute(snapshot_id, true) : update_snapshot_attribute(snapshot_id, false)
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def update_snapshot_attribute(snapshot_id, permission)
    snapshot = Snapshots::AWS.where(adapter_id: @adapter.id, region_id: @region.id,
                account_id: @adapter.account_id, provider_id: snapshot_id).first
    if snapshot.present?
      snapshot.update(publicly_accessible: permission)
      if snapshot.category.eql?'volume'
        provider_ids = Snapshot.where(provider_id: snapshot.provider_id).pluck("provider_data -> 'volume_id'")
        Service.scan_threats("Services::Compute::Server::Volume::AWS", @adapter,@region, provider_ids, true)
      else
        provider_ids = Snapshot.where(provider_id: snapshot.provider_id).pluck("provider_data -> 'instance_id'")
        Service.scan_threats("Services::Database::Rds::AWS", @adapter,@region, provider_ids, true)
      end
      CTLog.info "Snapshot access updated sucessfully"
    end
  end

  def attributes_for_delete_snap(parsed_data)
    status = :success
    event_ids = parsed_data.map { |e| e["eventID"] }
    resource_names = parsed_data.map { |e| e["provider_id"] }

    filters = { adapter_id: @adapter.id, region_id: @region.id,account_id: @adapter.account.id, provider_id: resource_names }
    services_to_remove = ServiceDetail.where(adapter_id: @adapter.id, region_id: @region.id, provider_id: resource_names)
    services_to_remove.delete_all unless services_to_remove.blank?
    CloudTrailLog.where(adapter_id: @adapter.id, :provider_id.in => resource_names).delete_all
    snapshots = Snapshot.where(filters)
    # Fixed n+1 query
    partition_snaps = snapshots.group_by(&:category).inject({}) { |memo, (key, values)| memo[key] = (key =='rds') ? values.pluck('provider_data').pluck('instance_id') : values.pluck('provider_data').pluck('volume_id') ; memo}
    snapshots.delete_all
    if partition_snaps.key? 'rds'
      partition_snaps['rds'].each do |id|
        Service.scan_threats("Services::Database::Rds::AWS", @adapter, @region, id, true)
      end
    end
    if partition_snaps.key? 'volume'
      partition_snaps['volume'].each do |id|
        Service.scan_threats("Services::Compute::Server::Volume::AWS", @adapter, @region, id, true)
      end
    end
  rescue StandardError => e
    status = :failure
    CTLog.error e
    CTLog.error e.backtrace
  ensure
    self.class.update_cloud_trail_event_status(@adapter.id, event_ids, status)
  end
end
