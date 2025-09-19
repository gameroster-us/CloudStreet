module CloudTrail::Events::Server::TerminateInstances

	def process
		# parse_events_data = parse_events([]) do |response,event_attributes,event|
		# 	event_attributes["attributes"].each do |attribute|
		# 		response << event_attributes.slice("region_code","eventTime","eventID").merge({"instanceId" => attribute["instanceId"], "attributes" => {"state" => attribute["state"]}})
		# 	end
		# 	response
		# end
		# parse_events_data

		parse_events_data = parse_events([]) do |response,event_attributes,event|
			response << event_attributes unless event_attributes.blank?
		end
		parse_events_data
	end
	
	def get_event_attributes(event)
		{"remote_service_id" => get_servers_for_state(event, ["shutting-down","terminated"]).map { |instance| instance["instanceId"] } }
	end
end