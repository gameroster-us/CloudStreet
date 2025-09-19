class AWSTrailFetcher < CloudStreetService
  extend SecurityScanHelper
  def self.get_uniq_account_trail_data
    AWSTrailFetcher.get_uniq_accounts("fetch_aws_trails")
  end

  def self.fetch_aws_trails(adapter)
    AWSTrail.where(adapter_id: adapter.id, aws_account_id: adapter.aws_account_id).delete_all
    arr_aws_trail_details = []
    Region.aws.each do |region|
      client = AWSSdkWrappers::AWSTrails::Client.new(adapter, region.code).client
      aws_trail_details = get_aws_trails_details(client, region.code).as_json
      next if aws_trail_details.blank?
      aws_trail_details.each do |aws_trail|
        aws_trail_name = aws_trail['name'] || 'aws_trail'
        aws_trail.merge!(
                         adapter_id: adapter.id,
                         region_id: region.id,
                         aws_account_id: adapter.aws_account_id,
                         provider_name: "#{aws_trail_name}/#{adapter.id}/#{adapter.aws_account_id}/#{region.id}"
                        )
        aws_trail.delete 'has_insight_selectors' if aws_trail.key? 'has_insight_selectors' # Add line while changing aws-sdk version
      end
      arr_aws_trail_details.concat(aws_trail_details) 
    end
    aws_trail_ids = AWSTrail.pluck(:provider_name, :id).to_h
    arr_aws_trail_details.each {|aws_trail| aws_trail[:id] = (aws_trail_ids[aws_trail[:provider_name]] || SecureRandom.uuid) } if aws_trail_ids.present?
    AWSTrail.import arr_aws_trail_details, on_duplicate_key_update: {conflict_target: [:id], columns: [:adapter_id, :region_id, :name, :cloud_watch_logs_log_group_arn, :cloud_watch_logs_role_arn, :home_region, :has_custom_event_selectors, :include_global_service_events, :is_multi_region_trail, :is_organization_trail, :kms_key_id, :log_file_validation_enabled, :s3_key_prefix , :s3_bucket_name, :sns_topic_name, :sns_topic_arn, :trail_arn, :created_at, :updated_at, :s3_bucket_server_access_logging, :provider_name, :aws_account_id ]}
    get_aws_trails(adapter)
  rescue Exception => e
    CSLogger.error "==== [AwsTrailFetcher] : Error while fetching awsTrail for security scanner for adapter #{adapter.try(:name)} ==="
    CSLogger.error "=== Error Message : #{e.message} ===="
    CSLogger.error "Backtrace : #{e.backtrace.first} ===="
  ensure
    # Update SecurityScanStorage data for AwsTrail
    SecurityScanner.scan_service_by_service_type('AWSTrail', adapter)
  end


  def self.get_aws_trails_details(client, region_code)
    begin 
      resp = client.describe_trails({}).try(:[], :trail_list)
    rescue Exception => e
      CSLogger.error "========Exception in get_aws_trails_details for region==#{region_code}====#{e.message}===="
      return nil
    end
  end 

  def self.get_aws_trails(adapter)
    arr_aws_trails = []
    Region.aws.each do |region|
      client = AWSSdkWrappers::AWSTrails::Client.new(adapter, region.code).client
      aws_trails = AWSTrail.where(adapter_id: adapter.id,aws_account_id: adapter.aws_account_id,region_id: region.id)
      next if aws_trails.blank?
      aws_trails.each do |aws_trail|
        aws_trail_event = get_event_selectors(client, aws_trail.name)
        aws_trail.data_resources = aws_trail_event.try(:data_resources).as_json
        aws_trail.include_management_events =  aws_trail_event.try(:include_management_events) || true
        aws_trail.latest_delivery_error = get_trail_status(client, aws_trail.name)
        aws_trail.s3_lock_configuration = get_s3_bucket_log_configuration(adapter, region.code,aws_trail.s3_bucket_name)
      end 
        arr_aws_trails.concat(aws_trails)
    end 
    AWSTrail.import arr_aws_trails, on_duplicate_key_update: {conflict_target: [:id], columns: [:data_resources, :latest_delivery_error, :s3_lock_configuration]}
  end

  def self.get_event_selectors(client, trail_name)
    begin 
      resp = client.get_event_selectors({ trail_name: trail_name}).try(:[], :event_selectors).try(:[], 0)
    rescue Aws::CloudTrail::Errors::TrailNotFoundException => e
      CSLogger.error "====Exception in get_event_selectors===#{e.message}====="
      return nil
    rescue Exception => e
      CSLogger.error "====Exception in get_event_selectors===#{e.message}====="
      return nil
    end
  end 

  def self.get_trail_status(client, trail_name)
    begin 
      resp = client.get_trail_status({ name: trail_name}).try(:latest_delivery_error)
    rescue Exception => e
      CSLogger.error "====Exception in get_trail_status===#{e.message}====="
      return nil
    end
  end 
  
  def self.get_s3_bucket_log_configuration(adapter, region_code, s3_bucket_name)
    begin 
      client = AWSSdkWrappers::S3::Client.new(adapter, region_code).client
      resp = client.get_object_lock_configuration({ bucket: s3_bucket_name})
    rescue Aws::S3::Errors::ObjectLockConfigurationNotFoundError => e
      CSLogger.error "====Exception in get_s3_bucket_log_configuration===#{e.message}= for region ==#{region_code}===="
      return []
    rescue Exception => e
      CSLogger.error "====Exception in get_s3_bucket_log_configuration===#{e.message}====for region ==#{region_code}=="
      return nil
    end
  end 



end
