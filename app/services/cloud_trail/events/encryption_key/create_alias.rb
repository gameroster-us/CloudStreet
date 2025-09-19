module CloudTrail::Events::EncryptionKey::CreateAlias

	def process
		parse_events_data = parse_events([]) do |response, event_attributes, event|
			response << event_attributes unless event_attributes.blank?
		end
		create_keys(parse_events_data)
	end

	def get_event_attributes(event)
		{ 
			"alias_name" => event["requestParameters"]["aliasName"],
			"key_id"	 => event["requestParameters"]["targetKeyId"]
		}
	end

	def create_keys(events)
		failed_event_ids = []
		not_found_events = []
		success_event_ids = events.each_with_object([]) do |event, success_event_ids|
			key_id = event["attributes"] && event["attributes"]["key_id"]
			alias_name = event["attributes"] && event["attributes"]["alias_name"]
			next if alias_name.blank?
			alias_name = alias_name.sub!('alias/', '')
			begin
				connection_object = ProviderWrappers::AWS::KMS.kms_agent(@adapter, @region.code)
				res = ProviderWrappers::AWS::KMS.fetch_key_info(connection_object, key_id)
				next if res.blank?
				res.transform_keys! { |key| key.underscore }
				res.merge!('key_alias' => alias_name, 'adapter_id' => @adapter.id, 'region_id' => @region.id, 'account_id' => @adapter.account_id)
				EncryptionKey.find_or_create_key(res)
				success_event_ids << event["eventId"]
			rescue Fog::AWS::KMS::Error => e
          		failed_event_ids << event["eventId"]
          		CTLog.error e.message
          	rescue Exception => e
          		if e.message.include?("does not exist")
          			not_found_events << event["eventId"]
          		else
	          		failed_event_ids << event["eventId"]
	          		CTLog.error e.message
	          		CTLog.error e.backtrace
	          	end
          	end
		end
		self.class.update_cloud_trail_event_status(@adapter.id, success_event_ids, :success) unless success_event_ids.blank?
		self.class.update_cloud_trail_event_status(@adapter.id, failed_event_ids, :failure) unless failed_event_ids.blank?
		self.class.update_cloud_trail_event_status(@adapter.id, not_found_events, :skipped_as_not_found) unless not_found_events.blank?
	end

end
