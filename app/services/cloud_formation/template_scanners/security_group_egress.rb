class CloudFormation::TemplateScanners::SecurityGroupEgress
  attr_accessor :template_data, :scan_details

  def initialize(template_data)
    @template_data = template_data
    @scan_details = CFNScanDetails::SecurityGroup
  end

   def start_template_scanning(resource)
    check_unrestricted_outboud_access(resource)
    template_data
  end

  ##Unrestricted Outbound Access on All Ports
  def check_unrestricted_outboud_access(res)
    if is_open_port_range(res['FromPort'], res['ToPort']) && is_port_open(res['CidrIp'])
      template_data << scan_details.unrestricted_outboud_access(res)
    end
  end

  private 

  def is_open_port_range(fromPort,toPort)
    fromPort.eql?(toPort) ? true : false
  end

  def is_port_open(cidrp)
    cidrp.eql?('0.0.0.0/0' || '::/0') ? true : false
  end

end



