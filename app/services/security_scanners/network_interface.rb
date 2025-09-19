module SecurityScanners::NetworkInterface
  def start_scanning
    network_interfaces = get_network_interface
    # return if network_interfaces.blank?
    new_network_interfaces = []
    SecurityScanners::ScannerObjects::NetworkInterface.parse(network_interfaces) do |network_interface|
      new_network_interfaces << network_interface
    end
    rule_sets = parse_scanning_rule_conditions
    new_network_interfaces.each do |network_interface|
      threats = []
      network_interface.scan(rule_sets) do |threat|
        if threat.present?
          threats << threat
        end
      end
      prepare_threats_to_import(network_interface, threats) if threats.present?
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

  def get_network_interface
    network_interface = Services::Network::NetworkInterface::AWS.select("id,name,provider_id,provider_data,data,state").where(adapter_id: @adapter.id, region_id: @region.id, state: "running")
    network_interface = network_interface.where(provider_id: @provider_ids) unless @provider_ids.blank?
    return network_interface.to_a
  end
  
  def prepare_threats_to_import(object, threats)
    @common_attributes ||= {account_id: @adapter.account_id, adapter_id: @adapter.id, region_id: @region.id}
    category = SecurityScanner::SERVICE_TYPE_CATEGORY_MAP[@service_type]
    threats.each do |threat|
      @results << @common_attributes.merge({
        provider_id: object.id,
        service_name: object.name,
        state: object.state,
        service_type: "Services::Network::NetworkInterface::AWS",
        category: category,
        scan_status: threat['level'],
        scan_details: threat['description'],
        scan_details_desc: threat['description_detail'],
        CS_rule_id: threat["CS_rule_id"],
        rule_type: threat["type"],
        environments: [],
        tags: SecurityScanner.convert_tags(object.tags),
        created_at: Time.now,
        updated_at: Time.now
      })
    end
  end
end
