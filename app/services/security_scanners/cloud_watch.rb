module SecurityScanners::CloudWatch
  def start_scanning
    cloud_watch_logs = get_cloud_watch_logs_data
    # return if cloud_watch_logs.blank?
    new_cloud_watch_logs = []
    SecurityScanners::ScannerObjects::CloudWatch.parse(cloud_watch_logs) do |cloud_watch_log|
      new_cloud_watch_logs << cloud_watch_log
    end
    rule_sets = parse_scanning_rule_conditions
    new_cloud_watch_logs.each do |cloud_watch_log|
      threats = []
      cloud_watch_log.scan(rule_sets) do |threat|
        threats << threat if threat.present?
      end
      prepare_threats_to_import(cloud_watch_log, threats) if threats.present?
    end
    clear_and_update_scan_report
  end

  def parse_condition(condition)
    operator = SecurityScanner::OPERATOR_MAP[condition[1]]
    case condition[1]
    when 'containAtLeastOneOf', 'includes', 'containNoneOf'
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

  def get_cloud_watch_logs_data
    cloud_watch_logs = AWSCloudWatchLog.where(aws_account_id: @adapter.aws_account_id, region_id: @region.id)
    cloud_watch_logs.to_a
  end

  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: "N/A",
        service_name: threat['metric_name'],
        service_type: "CloudWatch",
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        scan_details_desc: threat['description_detail'],
        rule_type: threat["type"],
        CS_rule_id: threat["CS_rule_id"],
        environments: [],
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end
end
