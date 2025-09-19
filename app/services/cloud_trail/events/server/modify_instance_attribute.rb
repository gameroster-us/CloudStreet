module CloudTrail::Events::Server::ModifyInstanceAttribute

  MODIFIY_KEYS = ["instanceInitiatedShutdownBehavior","instanceType", "disableApiTermination", "userData", "blockDeviceMapping"]

	def process
		parse_events_data = parse_events([]) do |response, event_attributes, event|
			unless event_attributes.blank?
				response << event_attributes.merge({"provider_id"  => event["requestParameters"]["instanceId"]})
			end
			response
		end
		parse_events_data
	end

	def get_event_attributes(event)
		CTLog.info "=====> Before #{event}"
		attributes = MODIFIY_KEYS.each_with_object({}) do |key,response|
			element = event["requestParameters"][key]
			if event["requestParameters"].has_key?(key) && !element.blank?
        element_value = key.eql?('blockDeviceMapping') ? element["items"] : element["value"]
        response.merge!({ key.underscore => element_value })
			end
		end
		attributes.merge!({"flavor_id" => attributes.delete("instance_type")}) if attributes.has_key?("instance_type")
		attributes.merge!({"launch_script" => attributes.delete("user_data")}) if attributes.has_key?("user_data")
		CTLog.info "=====> After #{attributes}"
		return attributes
	end
end