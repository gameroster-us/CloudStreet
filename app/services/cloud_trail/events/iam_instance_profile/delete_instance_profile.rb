module CloudTrail::Events::IamInstanceProfile::DeleteInstanceProfile
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "****** Inside DeleteInstanceProfile ******"
    parse_events_data = parse_events([]) { |response, event_attributes, event| response << event_attributes unless event_attributes.blank?; response  }
    process_parse_events_data(parse_events_data) do |parse_events_data, event_ids|
      parse_events_data.each do |parsed_event|
        aws_account_id = parsed_event["attributes"]["accountId"]
        role  = parsed_event["attributes"]["requestParameters"]["instanceProfileName"]
        IamRole.where(aws_account_id: aws_account_id, role: role).delete_all
      end
    end
  end

  def get_event_attributes(event)
    {
      "requestParameters" => event["requestParameters"],
      "accountId" => event["userIdentity"]["accountId"]
    }
  end
end
