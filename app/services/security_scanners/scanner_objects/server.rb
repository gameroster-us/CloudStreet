class SecurityScanners::ScannerObjects::Server < Struct.new(:id, :name, :state, :tags, :disable_api_termination, :is_asg_server ,:ec2_days_old_check, :ec2_iam_role_presence, :security_group_name_with_lunch_wizard,:ec2_instance_monitoring,:security_group_ids, :sg_permission_check, :is_auto_scaling_group, :hibernation_options, :image_id, :image_owner_alias)
  extend SecurityScanners::ScannerObjects::ObjectParser
  
  def scan(rule_sets, &block)
    rule_sets.each do |rule|
      status = eval(rule["evaluation_condition"])
      yield(rule) if status
    end
  end

  class << self
    def create_new(object)
      server_security_group_name = object.provider_data['groups'].blank? ? false : object.provider_data['groups'].any? {|security_group_name| security_group_name.start_with?('launch-wizard')}
      return new(
        object.provider_id,
        object.name,
        object.state,
        object.tags,
        object.disable_api_termination || false,
        object.data['is_asg_server'].eql?(true),
        object.provider_created_at.present? ? (object.provider_created_at < Time.now - 180.days) : false ,
        object.iam_role.present?,
        server_security_group_name,
        object.try(:instance_monitoring),
        object.security_group_ids,
        0,
        object.is_asg_server,
        object.try(:provider_data).try(:[],'hibernation_options'),
        object.image_id,
        nil
    )
    end
  end
  
end
