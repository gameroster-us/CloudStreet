class Services::Network::AvailabilityZone < Service
  INTERFACES = [Services::Vpc]
  store_accessor :data, :code
  attr_accessor :available_az_codes

  # def container
  #   true
  # end

  # def provides
  #   [
  #     { name: "subnet", protocol: Protocols::Subnet }
  #   ]
  # end

  def connected_to(service, via_services_map)
    if interfaces_includes?(service)
      case service.class.to_s
      when Services::Vpc.to_s
        vpc_id = ::Vpc.where(id: self.vpc_id).pluck(:vpc_id).first
        return  vpc_id && vpc_id.eql?(service.provider_id)
      end
    end
    false
  end


  def protocol
    "Protocols::AvailabilityZone"
  end

  def depends
    [
      # { name: "gateway", protocol: Protocols::IP }
    ]
  end

  def provides
    [
      { name: "AvailabilityZone", protocol: Protocols::AvailabilityZone }
    ]
  end
  
  def set_az_codes
    self.available_az_codes = ::AvailabilityZone::AVAILABILITY_ZONES[self.region.code] || self.adapter.available_az_names(self.region.code)
  end

  def properties
    set_az_codes
    [
      {
        name: "code",
        title: "Availability Zone Name",
        value: self.code || self.available_az_codes.try(:first),
        form_options: {
          type: "select",
          options: self.available_az_codes||[]
        },
        validation: '/^[a-zA-Z0-9-]*$/'
      }
    ]
  end

  def startup
    provision
  end

  def provision
    ;
  end

  def parent_services
    [Services::Vpc]
  end

  def is_created_and_not_in_error?
    true
  end

  def find_or_create_interface_connections(&services_context)
    return unless is_created_and_not_in_error?
    services_context.call.vpcs.each do |vpc|
      Interface.find_or_create_interfaces(self,vpc)
    end
  end

  def support_terminate?
    false
  end

  def self.create_az_service(subnet, organisation, environment, user) 
      az = Services::Network::AvailabilityZone.directory.non_generic_services.first
      new_az = az.dup
      new_az.code = subnet.availability_zone
      new_az.state = (environment.state == "pending") ? "environment" : "running"
      new_az.adapter_id = environment.default_adapter_id
      new_az.account_id = environment.account_id
      new_az.region_id = environment.region_id
      new_az.vpc_id = subnet.vpc.id
      service_vpc = environment.services.vpcs.where("data ->> 'vpc_id' = ?", subnet.vpc.provider_id).first
      new_az.service_vpc_id = service_vpc.id if service_vpc
      new_az.save
      environment.services << new_az      
      environment.save!
      new_az.find_or_create_default_interface_connections 
      Interface.find_or_create_interfaces(new_az, service_vpc) if service_vpc         
      new_az.set_additional_properties!
      new_az.save
      revision_data = environment.prepare_revision_data(event: 'added_to_environment', service: new_az.reload)   
      Events::Service::AddedToEnvironment.create(account: organisation.account, service: new_az.reload, environment: environment, user: user, revision_data: revision_data)
    end

  def self.create_synced_zones(attributes, az_codes)
    az_codes.collect do|zone|
      Services::Network::AvailabilityZone.create(
        attributes.merge({
          name: zone,
          state: "running",
          data: {"code"=>zone},
          provider_type: "Providers::AWS" ,
          generic_type: 'Services::Network::AvailabilityZone'
        })
      )
    end
  end
  private

  def set_parent_container_id
    first_remote_service = fetch_first_remote_service("Protocols::Vpc")
      if first_remote_service.present?
        first_remote_service.id
      else
        puts "#{self.try(:id)} | #{self.try(:name)} of #{self.try(:type)} Interface connection is removed from provider hence not found"
        nil
      end
  end

  def parent_service
    interfaces.of_type(Protocols::Vpc).first.remote_interfaces.first.service rescue nil
  end
end
