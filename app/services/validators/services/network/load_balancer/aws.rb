class Validators::Services::Network::LoadBalancer::AWS < Validators::Services::Network::LoadBalancer
  VALID_COMMON_PORTS = [25, 80, 443, 465, 587]
  VALID_COMMON_PROTOCOLS = ['HTTP', 'TCP', 'HTTPS', 'SSL']
  VALID_SECURE_PROTOCOLS = ['HTTPS', 'SSL']

  def validate_preconditions
    must_have_attribute :name

    must_have :vpc_service unless service_creation_event?
    must_have :subnet_services, error_key_name: :spc_subnets_connection unless service_creation_event?

    must_have_attribute :service_vpc_id if service_creation_event?
    must_have_attribute :subnet_ids if service_creation_event?
  end

  def validate_name
    check_format_of :name, validating_obj.name, with_regexp: ALPHA_NUM_HYPHEN_REGEXP
    check(:is_name_not_uniq?, across: 'region') { I18n.t('validator.error_msgs.attr_is_not_uniq', attr_type: 'name') } if template_provision_event?
    # check(:is_default_name_not_valid?) { I18n.t('validator.error_msgs.naming_convention_invalid', attr_type: 'name') }
  end

  def validate_scheme
    check_format_of :scheme, validating_obj.scheme, with_array: ::Services::Network::LoadBalancer::AWS::SCHEME_OPTIONS
  end

  def validate_spc_subnets_connection
    check(:is_subnet_connections_valid?) { I18n.t('validator.error_msgs.services.lb.subnet_same_az') }
  end

  def validate_listeners_lb_port    
    if parsed_listeners.present? 
      parsed_listeners.each_with_index do |listener, index|
        lb_port = listener['Listener']['lb_port'].to_i
        check(:listeners_lb_port_is_not_valid?, lb_port) { { index => I18n.t('validator.error_msgs.services.lb.invalid_port', port: lb_port) } }
      end
    end  
  end

  def validate_listeners_instance_port
    if parsed_listeners.present?
      parsed_listeners.each_with_index do |listener, index|
        instance_port = listener['Listener']['instance_port'].to_i
        check(:listeners_lb_port_is_not_valid?, instance_port) { { index => I18n.t('validator.error_msgs.services.lb.invalid_port', port: instance_port) } }
      end
    end  
  end

  def listeners_lb_port_is_not_valid?(port)
    valid = VALID_COMMON_PORTS.include?(port) || (1..65535).include?(port)
    !valid
  end

   def validate_listeners_protocol
    if parsed_listeners.present?
      parsed_listeners.each_with_index do |listener, index|
        protocol = listener['Listener']['protocol']
        instance_protocol = listener['Listener']['instance_protocol']
        check(:listeners_lb_protocol_is_not_valid?, protocol) { { index => I18n.t('validator.error_msgs.services.lb.invalid_protocol', protocol: protocol) } }
        check(:listeners_lb_protocol_is_not_valid?, instance_protocol) { { index => I18n.t('validator.error_msgs.services.lb.invalid_protocol', protocol: instance_protocol) } }
      end
    end  
  end

  def listeners_lb_protocol_is_not_valid?(protocol)
    valid = VALID_COMMON_PROTOCOLS.include?(protocol)
    !valid
  end

  def validate_certificates_for_ssh_and_https
     if parsed_listeners.present?

      certificate_error = {}
      parsed_listeners.each_with_index do |listener, index|

        protocol = listener['Listener']['protocol']
        instance_protocol = listener['Listener']['instance_protocol']
        ssl_certificate = listener['Listener']['ssl_certificate']
        new_ssl_certificate = listener['Listener']['new_ssl_certificate']
        ssl_type = listener['Listener']['ssl_type']
        check_for_valid_certificate_data(new_ssl_certificate) if ((VALID_SECURE_PROTOCOLS.include?(protocol) || VALID_SECURE_PROTOCOLS.include?(instance_protocol)) && new_ssl_certificate.present?)  
        certificate = (ssl_type == "old") ? ssl_certificate : new_ssl_certificate  
        check_for_valid_certificate_arn_present(certificate) if VALID_SECURE_PROTOCOLS.include?(protocol)
      end
    end   
  end

  def check_for_valid_certificate_data(new_ssl_certificate) 

      # if !validating_obj.ssl_certificate.present?
      #   check_for_valid_certificate_arn_present
      #   CSLogger.info "#{check_for_valid_certificate_arn_present}"
      # end
      
      check_for_valid_certificate_name(new_ssl_certificate)
      check_for_valid_private_key(new_ssl_certificate)
      check_for_valid_certificate(new_ssl_certificate)
  end

  def check_for_valid_certificate_arn_present(certificate)
      check(:certificate_arn_present_is_not_present?, certificate) { I18n.t('validator.error_msgs.services.lb.ssl_certificate_required')}
  end

  def certificate_arn_present_is_not_present?(certificate)
      !certificate.present?
  end

  def check_for_valid_certificate_name(new_ssl_certificate)

      check(:ssl_certificate_name_key_is_not_present?, new_ssl_certificate['certificate_name']) { I18n.t('validator.error_msgs.services.lb.ssl_certificate_name_required', attr_type: 'certificate_name') }
      check(:ssl_certificate_name_key_is_not_valid?, new_ssl_certificate['certificate_name']) { I18n.t('validator.error_msgs.services.lb.ssl_certificate_name_invalid', attr_type: 'certificate_name') }
      check(:check_name_in_available_certificates?, new_ssl_certificate['certificate_name']) { I18n.t('validator.error_msgs.services.lb.ssl_certificate_name_alredy_exist', attr_type: 'certificate_name') }
  end

  def ssl_certificate_name_key_is_not_present?(certificate_name)
      !certificate_name.present?
  end

  def ssl_certificate_name_key_is_not_valid?(certificate_name)
    certificate_name.match(/^[a-zA-Z0-9+=,.@_-]{1,128}$/).nil?
  end

  def check_name_in_available_certificates?(certificate_name)
      name_flag = false
        validating_obj.properties.each do |property|
          if property[:name] == 'ssl_certificate'
             property[:form_options][:options].each do |certificate|
              CSLogger.info certificate["ServerCertificateName"] == certificate_name
              name_flag = true if certificate["ServerCertificateName"] == certificate_name
             end
          end
      end
    name_flag
  end

  def check_for_valid_private_key(new_ssl_certificate)
     check(:ssl_private_key_is_not_present?, new_ssl_certificate['private_key']) { I18n.t('validator.error_msgs.services.lb.private_key_required') }
  end

  def ssl_private_key_is_not_present?(private_key)
      !private_key.present?
  end

  def check_for_valid_certificate(new_ssl_certificate)
      check(:ssl_certificate_is_not_present?, new_ssl_certificate['public_key_certificate']) { I18n.t('validator.error_msgs.services.lb.public_key_certificate_required') }
  end

  def ssl_certificate_is_not_present?(certificate)
      !certificate.present?
  end

  def parsed_listeners
    case validating_obj.listeners
    when String
       JSON.parse(validating_obj.listeners.gsub '=>', ':')
    else
      validating_obj.listeners
    end
  end

  def is_subnet_connections_valid?
    unless service_creation_event?
      az_code_map = subnet_services.map { |subnet| find_first_parent_service(Protocols::AvailabilityZone, of_service: subnet).code }.compact
    else
      az_code_map = Service.where(id: validating_obj.subnet_ids).map { |subnet| find_first_parent_service(Protocols::AvailabilityZone, of_service: subnet).code }.compact
    end  
    is_in_conflict = az_code_map.size != az_code_map.uniq.size # no two subnets should have same AZ
  end
end
