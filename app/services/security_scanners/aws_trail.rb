module SecurityScanners::AWSTrail
  def start_scanning
    aws_trails = get_aws_trail
    # return if aws_trails.blank?
    buckets_version_mfa_delete,buckets_versioning_status,buckets_permissions,buckets_logging_status = get_s3_buckets(aws_trails)
    new_aws_trail = []
    SecurityScanners::ScannerObjects::AWSTrail.parse(aws_trails) do |aws_trail|
      if aws_trail.s3_bucket_name.present?
        aws_trail.version_mfa_delete = buckets_version_mfa_delete[aws_trail.s3_bucket_name] 
        aws_trail.versioning_status = buckets_versioning_status[aws_trail.s3_bucket_name] 
        aws_trail.access_control_list = buckets_permissions[aws_trail.s3_bucket_name]
        aws_trail.logging = buckets_logging_status[aws_trail.s3_bucket_name]
      end  
      new_aws_trail << aws_trail   
    end
    rule_sets = parse_scanning_rule_conditions
    new_aws_trail.each do |aws_trail|
      threats = []
      aws_trail.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(aws_trail, threats) if threats.present?
    end
    clear_and_update_scan_report
  end

  def parse_condition(condition)
    operator = SecurityScanner::OPERATOR_MAP[condition[1]]
    case condition[1]
    when 'containAtLeastOneOf','includes','containNoneOf'
     "#{condition[2]}.#{operator}(#{condition[0]})"
    when 'notEmpty'
     "!#{condition[0]}.#{operator}"
    when 'datePriorTo'
         "Date.parse(#{condition[2]}) #{operator} Date.parse(#{condition[0]})"
    when 'isBlank?'
        "#{condition[0]}.#{operator}"
    else
     "#{condition[0]} #{operator} #{condition[2]}"
    end
  end

  def get_aws_trail
    aws_trail = ::AWSTrail.where(adapter_id: @adapter.id, region_id: @region.id).where.not(name: nil)
    return aws_trail.to_a
  end

  def get_s3_buckets(aws_trails)
    bucket_names = aws_trails.map{|trail| trail.s3_bucket_name}
    buckets = Storages::AWS.where(key: bucket_names).compact
    buckets_permissions = {}
    buckets_version_mfa_delete = {}
    buckets_versioning_status = {}
    buckets_logging_status = {}
     buckets.each do |bucket|
      buckets_permissions.merge!(bucket.key => bucket.access_control_list)
      buckets_version_mfa_delete.merge!(bucket.key => bucket.version_mfa_delete)
      buckets_versioning_status.merge!(bucket.key => bucket.versioning_status)
      buckets_logging_status.merge!(bucket.key => bucket.logging)
    end
    return buckets_version_mfa_delete,buckets_versioning_status,buckets_permissions,buckets_logging_status
  end
  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_name: object.name,
        service_type: "AWSTrail",
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        CS_rule_id: threat["CS_rule_id"],
        rule_type: threat["type"],
        scan_details_desc: threat['description_detail'],
        environments: [],
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end
end
