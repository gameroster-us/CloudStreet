module CloudTrail::Utils::EventConfigHelper

  UNLINKABLE_SERVICES = %w(Services::Network::SubnetGroup::AWS Services::Network::SecurityGroup::AWS)
  EVENTS = YAML.load_file(Rails.root.join("config/cloud_trail_events.yml"))

  def resources
  	EVENTS.keys
  end

  def events(key)
    return [] if key.blank? || resources.blank? || !resources.include?(key)
    EVENTS[key]['events']
  end

  def event_types(event_name)
    return if event_name.blank?
    event = EVENTS.select { |_k, v| (v['events'].include?(event_name) && v['type']) }
    return if event.blank?
    event[event.keys[0]]
  end

  def event_action_name(event_name)
    return if event_name.blank?
    event = EVENTS.select { |_k, v| (v['events'].include?(event_name) && !v['type']) }
    return if event.blank?
    "process_#{event.keys[0]}_event"
  end

  def get_service_type(event_name)
    event = EVENTS.select { |_k, v| (v['events'].include?(event_name) && v['type']) }
    return if event.blank?
    event[event.keys[0]]["type"]
  end


  def get_resource_type(event_name)
	  event = EVENTS.select { |_k, v| (v['events'].include?(event_name) && v['type']) }
    return if event.blank?
  	event[event.keys[0]]["resource_type"]
  end

  def filter_type(event_name)
	  event = EVENTS.select { |_k, v| (v['events'].include?(event_name) && v['type']) }
  	return if event.blank?
  	event[event.keys[0]]["filter_type"]
  end

  def generate_filters(resource_names, event_name)
    ftype = filter_type(event_name)
    {"#{ftype}": resource_names}
  end
end