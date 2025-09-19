class AdapterCloudwatch

  def adapter
    Fog::AWS::CloudWatch.new({
      aws_access_key_id:    adapter_info.access_key_id,
      aws_secret_access_key: adapter_info.secret_access_key
    })
  end
end