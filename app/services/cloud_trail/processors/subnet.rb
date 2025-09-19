class CloudTrail::Processors::Subnet
  include CloudTrail::Utils::ProcessorHelper

  def self.call(adapter, region_code_map, *args, &block)
	  service_type = args[0]["service_type"]
	  group_events = args[0]["group_events"]
	  group_events.each do |event|
	   obj = self.new(adapter, region_code_map[event["region_code"]], event["event_data"], service_type, event['event_name'])
	   obj.extend "CloudTrail::Events::Subnet::#{event['event_name']}".constantize
	   # obj.process
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
end