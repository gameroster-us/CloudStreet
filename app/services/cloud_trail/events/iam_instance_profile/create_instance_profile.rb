module CloudTrail::Events::IamInstanceProfile::CreateInstanceProfile
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside CreateInstanceProfile ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        aws_account_id = parsed_event["attributes"]["accountId"]
        role  = parsed_event["attributes"]["responseElements"]["instanceProfile"]["instanceProfileName"]
        instance_profile_id = parsed_event["attributes"]["responseElements"]["instanceProfile"]["instanceProfileId"]
        arn = parsed_event["attributes"]["responseElements"]["instanceProfile"]["arn"]
        IamRole.find_or_create_by(aws_account_id: aws_account_id,
                                  role: role, arn: arn, instance_profile_id: instance_profile_id)
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"],
      "accountId" => event["userIdentity"]["accountId"],
      "responseElements" => event["responseElements"]
    }
  end
end
