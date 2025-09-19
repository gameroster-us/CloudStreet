class CloudFormation::TemplateScanners::LoadBalancer

  attr_accessor :template_data, :scan_details

  def initialize(template_data)
    @template_data = template_data
    @scan_details = CFNScanDetails::LoadBalancer
  end

  def start_template_scanning(resource)
    check_elb_connection_daraining_enabled(resource)
    check_elb_cross_zone_enabled(resource)
    check_elb_listener_security(resource)
    check_internet_facing_elbs(resource)
    template_data
  end

  def check_elb_connection_daraining_enabled(res)
    template_data << scan_details.elb_connection_daraining_enabled(res) unless res['ConnectionDrainingPolicy'].try(:[], "Enabled")
  end

  def check_elb_cross_zone_enabled(res)
    template_data << scan_details.elb_cross_zone_enabled(res) unless res['CrossZone']
  end

  def check_elb_listener_security(res)
    if res['Listeners'].none? { |listener| ["HTTPS", "SSL"].include?(listener['Protocol']) }
      template_data << scan_details.elb_listener_security(res)
    end
  end

  def check_internet_facing_elbs(res)
    template_data << scan_details.internet_facing_elbs(res) unless res["Scheme"].eql?("internet-facing")
  end

end