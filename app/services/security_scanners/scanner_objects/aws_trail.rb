class SecurityScanners::ScannerObjects::AWSTrail < Struct.new(:id, :name ,:s3_bucket_name ,:version_mfa_delete, :versioning_status, :access_control_list ,:is_multi_region_trail, :include_global_service_events, :is_delivery_falling , :data_resources , :is_log_file_validation_enabled , :is_logs_encrypted_using_kms_key_id,:include_management_events, :logging ,:s3_lock_configuration, :is_ct_integrated_with_cloud_watch)
  extend SecurityScanners::ScannerObjects::ObjectParser
  
  def scan(rule_sets, &block)
    rule_sets.each do |rule|
    
      if rule["property"] == "grantees_with_URI"
        status = access_control_list.blank? ? false : access_control_list.any? { |access_control| eval(rule["evaluation_condition"]) }
      else
        status = eval(rule["evaluation_condition"])
      end
      yield(rule) if status
    end
  end

  class << self
    def create_new(object)
      return new(
        object.id,
        object.name,
        object.s3_bucket_name,
        nil,
        nil,
        [],
        object.is_multi_region_trail,
        object.include_global_service_events,
        object.latest_delivery_error.present?,
        object.data_resources,
        object.log_file_validation_enabled,
        object.kms_key_id,
        object.include_management_events,
        nil,
        object.s3_lock_configuration,
        object.cloud_watch_logs_log_group_arn
         
    )
    end
  end
  
end
