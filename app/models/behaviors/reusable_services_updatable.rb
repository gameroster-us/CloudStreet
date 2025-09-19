module Behaviors::ReusableServicesUpdatable
  REUSABLE_SERVICES = ['Services::Vpc', 'Services::Network::Subnet::AWS', 'Services::Network::SecurityGroup::AWS', 'Services::Network::SubnetGroup::AWS',
    'Services::Generic::Vpc', 'Services::Network::Generic::Subnet::AWS', 'Services::Network::Generic::SecurityGroup::AWS', 'Services::Network::Generic::SubnetGroup::AWS']
  def self.set_parser(service)
    parser = %W(Parsers ReusableServices AWS #{service.class::NETWORK_CLASS}).join("::").constantize.new
  end

  def self.network_filter(parser, service)
    parser.parse_for_filter(service)
  end

  def self.network_create(parser, service)
    parser.parse_for_create(service)
  end

  def self.network_update(parser, service)
    parser.parse_for_update(service)
  end

  def self.set_reusable_service(&services)
    CSLogger.info "services--in the resualbe--#{services.call.inspect}"
    services_data = services.call.where(type: REUSABLE_SERVICES)
    mapped_services = services_data.map(&:type)
    vpc_index = mapped_services.index('Services::Vpc') || mapped_services.index('Services::Generic::Vpc')
    sorted_services = services_data.to_a
    sorted_services.insert(0, sorted_services.delete_at(vpc_index)) if vpc_index.present?
    sorted_services.each do |service|
      parser = set_parser(service)
      filters = network_filter(parser, service)
      "#{service.class::NETWORK_CLASS}".constantize.find_or_create_reusable_service(filters) do |found_or_created_network_service|
      CSLogger.info "found_or_created_network_service-----#{found_or_created_network_service.inspect}-#{found_or_created_network_service.try(:provider_id).blank?}--------------#{service.provider_id.present?}-----#{service.provider_data.present?}"
        if found_or_created_network_service.new_record?
          CSLogger.info "----------new_record"
          found_or_created_network_service.assign_attributes network_create(parser, service)
          found_or_created_network_service.save!
          if service.vpc_id.blank? && service.type.include?('Vpc')
            services_data.each do |serv|
              next if serv.vpc_id.present?
              serv.vpc_id = found_or_created_network_service.id
              serv.data['vpc_id'] = nil
              serv.data_will_change!
              serv.save!
            end
          end
        elsif found_or_created_network_service.class.eql?(SubnetGroups::AWS) && !service.provider_id
          CSLogger.info "----------subnetgroup"
          found_or_created_network_service.update! network_create(parser, service)
          "#{service.class}".constantize.update_all_related_services(found_or_created_network_service, service) 
        elsif (found_or_created_network_service.try(:provider_id) || found_or_created_network_service.try(:group_id)).blank? && service.provider_id.present? && service.provider_data.present?
          CSLogger.info "----------exsisint----#{found_or_created_network_service.try(:provider_id)}--------------#{service.provider_id.present?}-----#{service.provider_data.present?}"
          found_or_created_network_service.update! network_update(parser, service)
          "#{service.class}".constantize.update_all_related_services(found_or_created_network_service, service)
        elsif found_or_created_network_service.class.eql?(Vpcs::AWS) && service.vpc_id.blank?
          CSLogger.info "----------update vpc_id"
          services_data.each do |serv|
            next if serv.vpc_id.present?
            serv.vpc_id = found_or_created_network_service.id
            serv.data['vpc_id'] = nil
            serv.data_will_change!
            serv.save!
          end
        end
      end
    end
  end
  
  def self.create_remote_services_from_pending(service_uuids, network_service_class, service_type, parent_service)
    network_services = network_service_class.constantize.where(id: service_uuids)#search from SG::AWS
    environment_services = parent_service.environment.services.where(type: service_type)
    provider_ids = []
    network_services.each do |network_service|
      unless network_service.is_service_present_in_environment_services?(environment_services) # if service is not present in the environment
        vpc_service = parent_service.fetch_first_remote_service(Protocols::Vpc)
        created_service = network_service.create_remote_services_from_pending(parent_service.user, vpc_service, parent_service.environment, parent_service)
        provider_ids << created_service.provider_id 
      else
        provider_ids << network_service.provider_id
      end
    end
    provider_ids
  end

  def self.update_reusable_service_with_its_dependencies_for_name(service)
    return unless REUSABLE_SERVICES.include?(service.type)
    reusable_service = service.fetch_associated_reusable_service_object
    return unless reusable_service
    reusable_service.update_attribute(:name, service.name)
    "#{service.class}".constantize.update_all_related_services(reusable_service, service)
  end
end