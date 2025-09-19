module CloudTrail::Events::Tag::DeleteTags
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside DeleteTags ******"
    exec_tag_events do
      snap_resources = {}
      service_resoures = {}
      @events.each do |event|
        request_parameters = event["cloud_trail_event"]["requestParameters"]
        if event["cloud_trail_event"]["eventSource"].eql?("autoscaling.amazonaws.com")
          removed_tags = (request_parameters["tags"] || []).group_by { |h| h["resourceId"] }.transform_values { |value| value.pluck("key") }
          removed_tags.each { |resource_id, tags| (service_resoures[resource_id] ||= []).concat(tags) }
          next
        end
        resource_set = request_parameters["resourcesSet"] || {} rescue nil
        resource_id = resource_set["items"][0]["resourceId"] rescue nil
        tag_set    = request_parameters["tagSet"] || {} rescue nil
        next if resource_id.blank?  || tag_set.blank? || !tag_set.key?("items")
        resource = resource_id.split('-').first.eql?("snap") ? snap_resources : service_resoures
        (resource[resource_id] ||= []).concat(tag_set["items"].pluck("key"))
      end

      filter = {adapter_id: @adapter.id, region_id: @region.id, account_id: @adapter.account_id}
      if snap_resources.present?
        snapshots = Snapshots::AWS.active_snapshots.where(filter).where(provider_id: snap_resources.keys.uniq)
        delete_tag_from_services(snapshots,snap_resources)
      end

      if service_resoures.present?
        services = Service.active_services.where(filter).where(generic_type: CloudTrail::Processors::Tag::TAG_SERVICES + ["Services::Network::AutoScaling"],provider_id: service_resoures.keys.uniq)        
        delete_tag_from_services(services,service_resoures)
        grouped_network_services = services.where(generic_type: CloudTrail::Processors::Tag::TAG_NETWORK_SERVICES.keys).group_by { |s| s.generic_type }.transform_values { |values| values.pluck(:provider_id).compact.uniq }
        grouped_network_services.each do |service_type, provider_ids|
          delete_tag_from_base_table(service_resoures, filter, provider_ids, CloudTrail::Processors::Tag::TAG_NETWORK_SERVICES[service_type])  if CloudTrail::Processors::Tag::TAG_NETWORK_SERVICES.keys.include?(service_type)
        end
      end
    end
  end
end
