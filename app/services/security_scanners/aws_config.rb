module SecurityScanners::AWSConfig
  def start_scanning
    aws_configs = get_aws_config
    # return if aws_configs.blank?
    new_aws_config = []
    SecurityScanners::ScannerObjects::AWSConfig.parse(aws_configs) do |aws_config|
      new_aws_config << aws_config
    end
    rule_sets = parse_scanning_rule_conditions
    new_aws_config.each do |aws_config|
      threats = []
      aws_config.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(aws_config, threats) if threats.present?
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

  def get_aws_config
    aws_config = AWSConfig.where(adapter_id: @adapter.id, aws_account_id: @adapter.aws_account_id , region_id: @region.id)
    return aws_config.to_a
  end
  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_type: "AWSConfig",
        service_name: object.name,
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        scan_details_desc: threat['description_detail'],
        CS_rule_id: threat["CS_rule_id"],
        rule_type: threat["type"],
        environments: [],
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end

end
