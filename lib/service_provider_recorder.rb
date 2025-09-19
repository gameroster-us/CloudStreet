module ServiceProviderRecorder

  def save_service_to_db(adapter, region, provider_data, additional_attributes = {})
    aws_record = AWSRecord.new
    aws_record.provider_id = provider_data.try(:id)||provider_data.try(:group_id)||provider_data.try(:subnet_id)||provider_data.try(:network_acl_id)
    aws_record.adapter = adapter
    aws_record.region = region
    aws_record.account = adapter.account
    aws_record.data = provider_data.to_json
    aws_record.service_type = provider_data.class.to_s.split("AWS::").last
    if aws_record.service_type == AWSRecord::ELASTIC_IP
      aws_record.provider_id = provider_data.try(:public_ip)
    end
    aws_record.data.merge!(additional_attributes)
    aws_record.save
  end

end