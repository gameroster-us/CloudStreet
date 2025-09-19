module CloudTrail::Events::Ami::ModifyImageAttribute
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "** Inside ModifyImageAttribute ***"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes.merge({"provider_id" => event["requestParameters"]["imageId"]}) unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        ami_id = parsed_event["provider_id"]
        permission = parse_permission(parsed_event["attributes"]["requestParameters"]["launchPermission"])
        next if permission.blank?
        is_public = permission.eql?("public") ? "t" : "f"
        create_or_update_ami(ami_id, is_public)
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"]
    }
  end

  def parse_permission(launchPermission)
    return if launchPermission.blank?
    launchPermission.keys.include?("add") ? "public" : "private"
  end

  def create_or_update_ami(ami_id, permission)
    if permission.eql?("f")
      create_at_local(ami_id)
      delete_from_central_api(ami_id)
    elsif permission.eql?("t")
      delete_from_local(ami_id)
      create_at_central_api(ami_id) if !present_in_central_api(ami_id)
    end
  end

  def present_in_central_api(ami_id)
    filters = {id: ["#{@region.code}-#{ami_id}"]}
    ProviderWrappers::CentralApi::MachineImages.find(filters).present?
  end

  def create_at_local(ami_id)
    raw_machine_image = @adapter.fetch_amis(@region, { "image-id" => ami_id }).first
    machine_image = MachineImage.create_machine_image(@adapter, @region, raw_machine_image, @adapter.generic_adapter.id) if raw_machine_image
  end

  def delete_from_local(ami_id)
    @adapter.images.where(active: true, is_public: false, image_id: ami_id).update_all(active: false)
  end

  def create_at_central_api(ami_id)
    raw_machine_image = @adapter.fetch_amis(@region, { "image-id" => ami_id }).first
    return if raw_machine_image.blank?
    cost = MachineImage.calculate_and_update_hourly_cost(raw_machine_image)
    raw_machine_image["cost_by_hour"] = cost
    raw_machine_image["region"] = @region.code
    begin
      ProviderWrappers::CentralApi::MachineImages.create(raw_machine_image)
    rescue CentralApiNotReachable => e
      CTLog.error "CentralApiError : #{e.message}"
      Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
    end
  end

  def delete_from_central_api(ami_id)
    begin
      ProviderWrappers::CentralApi::MachineImages.archive_images("#{@region.code}-#{ami_id}")
    rescue CentralApiNotReachable => e
      CTLog.error "CentralApiError : #{e.message}"
      Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
    end
  end

end
