module SecurityScanners::KMSKeys
  def start_scanning
    kms_keys = get_kms_key
    # return if kms_keys.blank?
    new_kms_key= []
    SecurityScanners::ScannerObjects::KMSKeys.parse(kms_keys) do |kms_key|
      new_kms_key << kms_key
    end
    rule_sets = parse_scanning_rule_conditions
    new_kms_key.each do |kms_key|
      threats = []
      kms_key.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(kms_key, threats) if threats.present?
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

  def get_kms_key
    kms_key = EncryptionKey.where(adapter_id: @adapter.id, region_id: @region.id)
    return kms_key.to_a
  end

  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_name: object.name,
        state: object.state,
        service_type: "EncryptionKey",
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        rule_type: threat["type"],
        CS_rule_id: threat["CS_rule_id"],
        scan_details_desc: threat['description_detail'],
        environments: [],
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end
end
