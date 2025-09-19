class Services::Network::AutoScaling < Service
  # store_accessor :data, :allocation_id

  def provides
    [
      { name: "auto_scaling", protocol: Protocols::AutoScaling }
    ]
  end

  def protocol
    "Protocols::AutoScaling"
  end

  def create_service_interfaces(params)
    availability_zone_codes = params[:availability_zones].split(",") #az
    subnet_ids = params[:vpc_zone_identifier].split(",") #subnet
    launch_configuration_name = params[:launch_configuration_name]
    return unless service_params_present?(params)
    load_balancer_ids = params[:load_balancers]

    subnet = Service.find subnet_ids.first
    vpc = subnet.fetch_first_remote_service(Protocols::Vpc)
    create_interface(vpc)


    lc = environment.services.auto_scalling_configurations.where(provider_id: launch_configuration_name).first

    create_interface(lc)
    lc.additional_properties_will_change!
    lc.set_additional_properties! if lc.provider_id
    lc.save!

    availability_zone_codes.each do |availability_zone_code|
      az = environment.services.availability_zones.where("data->>'code'=?", availability_zone_code).first
      if az.present?
        create_interface(az)
      else
        new_az = environment.services.availability_zones.first.dup
        params = {name: 'az', code: availability_zone_code, vpc_id: vpc.id}
        new_az.update!(params)
        new_az.reload
        environment.services << new_az
        new_az.initialize_interface(interface_type: Protocols::AvailabilityZone, depends: false)
        Interface.find_or_create_interfaces(new_az, vpc)
        create_interface(new_az)
      end
    end
    subnet_ids.each do |subnet_id|
      subnet = environment.services.subnets.where(id: subnet_id).first
      create_interface(subnet)
    end
    load_balancer_ids.each do |lb|
      lb_obj = environment.services.load_balancers.where(provider_id: lb).first
      create_interface(lb_obj) if lb_obj
    end unless load_balancer_ids.nil?
  end

  def create_interface(parent)
    Interface.find_or_create_interfaces(self, parent) if parent
  end

  def service_params_present?(params)
    availability_zone_codes = params[:availability_zones].split(",") #az
    subnet_ids = params[:vpc_zone_identifier].split(",") #subnet
    launch_configuration_name = params[:launch_configuration_name] #Lc
    availability_zone_codes.present? && subnet_ids.present? && launch_configuration_name.present?
  end
end
