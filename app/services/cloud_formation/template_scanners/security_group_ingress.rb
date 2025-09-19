class CloudFormation::TemplateScanners::SecurityGroupIngress

  attr_accessor :template_data, :scan_details

  KNOWN_PORTS = [20, 21, 22, 23, 25, 53, 80, 135, 137, 138, 139, 443, 445, 1433, 1521, 3306, 3389, 5432, 9200, 27017]

  def initialize(template_data)
    @template_data = template_data
    @scan_details = CFNScanDetails::SecurityGroup
  end

  def start_template_scanning(resource)
    check_sg_port_range(resource)
    check_unrestricted_port_access(resource)
    check_non_http_ports_open_to_all(resource)
    check_known_ports_open_to_all(resource)
    check_known_ports_open_to_self(resource)
    check_all_ports_open_to_all(resource)
    check_RFC_1918(resource)
    template_data
  end

  ##Security Group Port Range
  def check_sg_port_range(res)
    if check_protocol(res['IpProtocol']) && !is_open_port_range(res['FromPort'], res['ToPort']) && !Range.new(res['FromPort'].to_i,res['ToPort'].to_i).include?(0..65535)
      template_data << scan_details.sg_port_range(res)
    end
  end

  ##Unrestricted port Access
  def check_unrestricted_port_access(res)
    if check_protocol(res['IpProtocol']) && is_open_port_range(res['FromPort'], res['ToPort']) && is_port_open(res['CidrIp'])
      if (res['IpProtocol'].eql?("tcp") && res['FromPort'].eql?(139)) || (res['IpProtocol'].eql?("udp") && res['FromPort'].eql?(137 || 138))
        template_data << scan_details.unrestricted_netbios_port_access(res)
      elsif (KNOWN_PORTS - [139, 137, 138]).include?(res['FromPort'])
        template_data << scan_details.unrestricted_port_access(res)
      end
    end
  end

  ##Security Group non HTTP Ports Open to All (TCP/UDP)
  def check_non_http_ports_open_to_all(res)
    if check_protocol(res['IpProtocol']) && is_open_port_range(res['FromPort'], res['ToPort']) && !(KNOWN_PORTS - [80]).include?(res['FromPort']) && is_port_open(res['CidrIp'])
      template_data << scan_details.non_http_ports_open_to_all(res)
    end
  end

  ##Security Group known Ports Open to All
  def check_known_ports_open_to_all(res)
    if check_protocol(res['IpProtocol']) && is_open_port_range(res['FromPort'],res['ToPort']) && is_known_port(res['FromPort']) && is_port_open(res['CidrIp'])
      template_data << scan_details.known_Ports_open_to_all(res)
    end
  end

  ##Security Group known Ports to Self
  def check_known_ports_open_to_self(res)
    if check_protocol(res['IpProtocol']) && is_open_port_range(res['FromPort'],res['ToPort']) && res['GroupId'].eql?(res['CidrIp']) &&  res['GroupId'].present?
      template_data << scan_details.known_ports_open_to_self(res)
    end
  end

  ##Security Group All Ports Open to All
  def check_all_ports_open_to_all(res)
    if check_protocol(res['IpProtocol']) && is_port_open(res['CidrIp'])
      template_data << scan_details.all_ports_open_to_all(res)
    end
  end

  ##SecurityGroup RFC 1918
  def check_RFC_1918(res)
    if ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"].include?(res['CidrIp'])
      template_data << scan_details.rfc_1918(res)
    end
  end

  private

  def check_protocol(protocol)
    ["-1", "udp", "tcp"].include?(protocol) ? true : false
  end

  def is_open_port_range(fromPort,toPort)
    fromPort.eql?(toPort) ? true : false
  end

  def is_port_open(cidrp)
    cidrp.eql?('0.0.0.0/0' || '::/0') ? true : false
  end

  def is_known_port(port)
    KNOWN_PORTS.include?(port)
  end


end
