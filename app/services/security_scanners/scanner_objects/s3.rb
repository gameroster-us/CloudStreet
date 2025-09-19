class SecurityScanners::ScannerObjects::S3 < Struct.new(:key, :access_control_list, :logging, :version_mfa_delete, :versioning_status, :web_hosting , :owner_id, :owner_display_name, :name, :state, :names_contain_periods)
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
  		names_check =  object.name.ends_with?(".") || object.name.starts_with?(".") || object.name.include?("..")
  		return new(
  			object.key,
			object.access_control_list,
			object.logging, 
			object.version_mfa_delete, 
			object.versioning_status, 
			object.web_hosting,
			object.owner_id,
			object.owner_display_name,
			object.name,
			object.state,
			names_check
		)
  	end
  end
end