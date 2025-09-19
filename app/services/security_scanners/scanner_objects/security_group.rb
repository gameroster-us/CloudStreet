class SecurityScanners::ScannerObjects::SecurityGroup < Struct.new(:name, :group_id, :tags, :ip_permissions, :ip_permissions_egress, :vpc_id, :owner_id, :default, :associated_service_count, :associated_rules_count, :security_group_descriptions)
	extend SecurityScanners::ScannerObjects::ObjectParser

  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      if rule.has_key?("property") && rule["property"].eql?("ip_permissions") && ip_permissions.present?
        ip_permission_status = []
        ip_permissions.each do |ip_permission|
          ip_permission['fromPort'] ||= 0
          ip_permission['toPort'] ||= 65535
          status = eval(rule["evaluation_condition"]) rescue false
          if status
            threat1 = rule.deep_dup
            threat1["description"].gsub!("_PORT_",ip_permission['toPort'].to_s)
            threat1["description_detail"].gsub!("_PORT_",ip_permission['toPort'].to_s)
            ip_permission_status << status
          end
        end
        yield(rule) if ip_permission_status.any?
      elsif rule.has_key?("property") && rule["property"].eql?("ip_permissions_egress") && ip_permissions_egress.present?
        ip_permission_egress_status = []
        ip_permissions_egress.each do |ip_permission_egress|
          ip_permission_egress['fromPort'] ||= 0
          ip_permission_egress['toPort'] ||= 65535
          status = eval(rule["evaluation_condition"]) rescue false
          if status
            threat1 = rule.deep_dup
            threat1["description"].gsub!("_PORT_",ip_permission_egress['toPort'].to_s)
            threat1["description_detail"].gsub!("_PORT_",ip_permission_egress['toPort'].to_s)
            ip_permission_egress_status << status
          end
        end
        yield(rule) if ip_permission_egress_status.any?
      else
        status = eval(rule["evaluation_condition"]) rescue false
        yield(rule) if status
      end
    end
  end


	class << self
	  	def create_new(object)
	  		default = object.parsed_provider_data["default"].blank? ? false : object.parsed_provider_data["default"]
	  		group_rules_count_check = (object.provider_data["ip_permissions"].count + object.provider_data["ip_permissions_egress"].count) <= 50 
	  		rules_description = object.provider_data["ip_permissions"].map{|m| m["description"].present?}.all?{|m| m == true}
	  		return new(
				object.parsed_provider_data["name"], 
				object.parsed_provider_data["group_id"],
				object.provider_data["tags"],
				object.parsed_provider_data["ip_permissions"], 
				object.parsed_provider_data["ip_permissions_egress"], 
				object.parsed_provider_data["vpc_id"], 
				object.parsed_provider_data["owner_id"],
				default,
				0,
				group_rules_count_check,
				rules_description
			)
	  	end
	end
end