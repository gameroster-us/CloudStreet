class CloudFormation::TemplateScanners::SecurityGroup

  attr_accessor :template_data

  def initialize(template_data)
    @template_data = template_data
  end

  def start_template_scanning(resource)
    check_security_group_ingress_rules(resource)
    check_security_group_egress_rules(resource)
    template_data
  end

  def check_security_group_ingress_rules(res)
    return if res['SecurityGroupIngress'].blank?
    res['SecurityGroupIngress'].each do |sg_ingress|
      sg = CloudFormation::TemplateScanners::SecurityGroupIngress.new(template_data)
      sg.start_template_scanning(sg_ingress)
    end
  end

  def check_security_group_egress_rules(res)
    return if res['SecurityGroupEgress'].blank?
    res['SecurityGroupEgress'].each do |sg_ingress|
      sg = CloudFormation::TemplateScanners::SecurityGroupEgress.new(template_data)
      sg.start_template_scanning(sg_ingress)
    end
  end

end