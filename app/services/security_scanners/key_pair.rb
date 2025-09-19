module SecurityScanners::KeyPair
  def start_scanning
    key_pairs = get_key_pair
    # return if key_pairs.blank?
    server_with_key = get_severs_with_keys(get_key_pair)
    # return if server_with_key.blank?
    new_key_pairs = []
    SecurityScanners::ScannerObjects::KeyPair.parse(key_pairs) do |key_pair|
      key_pair.valid_KeyPair = server_with_key.include?(key_pair.name)
      new_key_pairs << key_pair
    end
    rule_sets = parse_scanning_rule_conditions
    new_key_pairs.each do |key_pair|
      threats = []
      key_pair.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(key_pair, threats) if threats.present?
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

  def get_key_pair
    key_pairs = Resources::KeyPair.where(adapter_id: @adapter.id, region_id: @region.id)
    return key_pairs.to_a
  end

  def get_severs_with_keys(get_key_pair)
    server = Services::Compute::Server::AWS.select("id,name,state,data,provider_data").where(adapter_id: @adapter.id, region_id: @region.id).active_services
    server_keys = server.map{|s|s.key_name}.compact
    return server_keys
  end

  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_name: object.name,
        state: "N/A",
        service_type: "Resources::KeyPair",
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
