module SecurityScanners::Volume
  def start_scanning
    volume = get_volume
    # return if volume.blank?
    new_volumes = []
    stopped_servers = get_stopped_servers
    snapshots = get_volume_snapshots(volume) || []
    snapshots = get_snapshot_ids(snapshots) || []
    volumes = get_volume_in_active_record(volume.pluck('id'))
    SecurityScanners::ScannerObjects::Volume.parse(volumes) do |volume|
      volume.volumes_attached_with_stopped_ec2 = stopped_servers.include?(volume.server_id) if volume.server_id.present? 
      volume.ebs_volumes_recent_snapshot = snapshots.include?(volume.snapshot_id) if volume.snapshot_id.present? 
      new_volumes << volume
    end
    rule_sets = parse_scanning_rule_conditions
    new_volumes.each do |volume|
      threats = []
      volume.scan(rule_sets) do |threat|
        if threat.present?
          if ((volume.public_snapshot_names.present?) && (threat['property'].eql?'snapshot'))
            threat['description_detail'] = threat['description_detail'] + "Publicly accessible Snapshots #{volume.public_snapshot_names}" if threat['description_detail'].present?
          elsif((volume.non_encrypted_snapshot_names.present?) && (threat['property'].eql?'encryption_snapshot'))
            threat['description_detail'] = threat['description_detail'] + "Non Encrypted Snapshots #{volume.non_encrypted_snapshot_names}" if threat['description_detail'].present?
          end
          threats << threat
        end
      end
      prepare_threats_to_import(volume, threats) if threats.present?
    end
    clear_and_update_scan_report
  end

  def parse_condition(condition)
    operator = SecurityScanner::OPERATOR_MAP[condition[1]]
    case condition[1]
    when 'containAtLeastOneOf','includes','containNoneOf'
     "#{condition[2]}.#{operator}(#{condition[0]})"
    when 'notEmpty'
     "!#{condition[0]}.#{operator}"
    when 'datePriorTo'
         "Date.parse(#{condition[2]}) #{operator} Date.parse(#{condition[0]})"
        when 'isBlank?'
         "#{condition[0]}.#{operator}"
    else
     "#{condition[0]} #{operator} #{condition[2]}"
    end
  end

  def get_volume
    volume = Services::Compute::Server::Volume::AWS.where(adapter_id: @adapter.id, region_id: @region.id, state: "running").where.not(provider_id: nil).as_json(only: [:id, :provider_id, :provider_data])
    volume = volume.select{ |vol| @provider_ids.include? vol['provider_id'] } unless @provider_ids.blank?
    volume
  end

  def get_stopped_servers
    stopped_servers_provider_ids = Services::Compute::Server::AWS.where(adapter_id: @adapter.id, region_id: @region.id, state: "stopped").pluck('provider_id')
    stopped_servers_provider_ids = stopped_servers_provider_ids.select{ |prov_id| @provider_ids.include? prov_id } unless @provider_ids.blank?
    stopped_servers_provider_ids
  end

  def get_volume_snapshots(volume)
    snapshot_ids = volume.map{|vol| vol['provider_data']["snapshot_id"]}.compact
    Snapshots::AWS.where(provider_id: snapshot_ids, adapter_id: @adapter.id, region_id: @region.id) unless snapshot_ids.blank?
  end

  def get_snapshot_ids(snapshots)
    snapshots.where('created_at < ? ',  Time.now - 7.days).pluck(:provider_id) if snapshots.any?
  end
  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_name: object.name,
        state: object.state,
        service_type: "Services::Compute::Server::Volume::AWS",
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        scan_details_desc: threat['description_detail'],
        CS_rule_id: threat["CS_rule_id"],
        rule_type: threat["type"],
        environments: [],
        tags: SecurityScanner.convert_tags(object.tags),
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end

  def get_volume_in_active_record(volume_ids)
    Services::Compute::Server::Volume::AWS.select("id, name, provider_id, provider_data, data, state").where(id: volume_ids).to_a
  end
end
