module ServiceDataInfoRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :name
  property :type
  property :generic_type
  property :vpc_id
  property :region_id
  property :state
  property :provider_id
  property :get_service_tags, as: :service_tags
  property :get_associations, as: :is_reusable

  # subnet
  property :cidr_block, if: lambda { |opts| self.generic_type.eql?('Services::Network::Subnet') }
  property :availability_zone, if: lambda { |opts| self.generic_type.eql?('Services::Network::Subnet') }
  # property :get_az_name_from_interface_or_provider_data, as: :availability_zone, if: lambda { |opts| self.kind_of?(Services::Network::Subnet) }

  # server
  property :get_subnet_cidr_from_interface, as: :subnet_id, if: lambda { |opts| self.kind_of?(Services::Compute::Server) }
  property :private_ip_address, if: lambda { |opts| self.kind_of?(Services::Compute::Server) }

  # securitygroup
  property :uniq_provider_id, if: lambda { |opts| self.generic_type.eql?('Services::Network::SecurityGroup') }

  def get_associations
    self.is_reusable? if TemplateServiceInfo::REUSABLE_SERVICE_CLASS.include?("#{self.class}")    
  end

   def get_service_tags
    if ['Services::Network::Subnet::AWS', 'Services::Network::SecurityGroup::AWS'].include?("#{self.class}")
      template_env_count = self.is_reusable?
      if template_env_count[:service_in_template] > 0 && template_env_count[:service_in_environment] == 0
        templated_service_tags = find_temp_service_tags
        return templated_service_tags
      else
        environmented_service_tags  = find_env_service_tags
        return environmented_service_tags
      end
    else
     self.respond_to?(:service_tags) ? self.service_tags : []   if Service::TAGGABLE_SERVICES.include?(self.class)
    end
  end
  
  def find_temp_service_tags
    if self.is_subnet?
      service_in_template = self.data['cidr_block'].nil? ? [] : self.class.in_template.where(vpc_id: self.vpc_id).where("data ->> 'cidr_block' = ?", self.cidr_block)
      service_tags = nil
     service_in_template.each do |service|
      next if service.service_tags.blank?
      return service_tags =  service.service_tags
     end
     service_tags.blank? ? [] : service_tags
    else
     service_tags.blank? ? [] : service_tags
    end
  end

  def find_env_service_tags
    if self.is_subnet?
      service_in_environment = self.data['cidr_block'].nil? ? [] : self.class.in_environment.subnets.where(vpc_id: self.vpc_id).where("data ->> 'cidr_block' = ?", self.cidr_block)
      service_tags = nil
     service_in_environment.each do |service|
      next if service.service_tags.blank?
      return service_tags = service.service_tags
     end
     service_tags.blank? ? [] : service_tags
    else
     service_tags.blank? ? [] : service_tags
    end
  end
end
