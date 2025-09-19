module EnvironmentParentServicesRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  include ServiceRepresenterName

  property :parent_services, getter: lambda { |args|
    env_vpc_id = self.vpcs.first.try(:id)
    final_service_attributes = Array.new
    service_type = args[:options][:service_type]
    env_services =  case service_type
    when "Services::Vpc"
      self.services.vpcs
    when "Services::Compute::Server::AWS"
      self.services.instance_servers
    when "Services::Compute::Server::Volume::AWS"
      self.services.volumes
    when "Services::Database::Rds::AWS"
      self.services.databases
    when "Services::Network::AutoScalingConfiguration::AWS"
      self.services.auto_scalling_configurations
    else
      self.services
    end

    env_services.order('created_at').map do |service|
      next if service.state.eql?('terminated') # ignore terminated services
      next if service_type.present? && service.type != service_type

      if (service.generic_type.eql?('Services::Vpc')) || (service.generic_type.eql?('Services::Network::SecurityGroup')) || (service.generic_type.eql?('Services::Network::RouteTable')) || (service.type.include? 'Database') || (service.generic_type.eql?('Services::Compute::Server')) || (service.generic_type.eql?('Services::Network::LoadBalancer')) || (service.generic_type.eql?('Services::Compute::Server::Volume')) || (service.type.include? 'AutoScalingConfiguration') || (service.type.include? 'Services::Network::SubnetGroup') || (service.generic_type.include? 'Services::Network::ElasticIP')|| (service.generic_type.include? 'Services::Network::NetworkInterface')
        updated_representers = ["Services::VpcRepresenter","Services::Compute::ServerRepresenter::AWSRepresenter"]
        representer_name = find_service_representer(service)
        representer_name = "Environments::#{representer_name}" if updated_representers.include?(representer_name)
        p "-----parent_final_type------#{representer_name}---------------"
        service_hash = service.extend(representer_name.constantize).to_hash
        service_hash['env_vpc_id'] = env_vpc_id
        service_hash['cost_to_date'] = 0
        service_hash['current_month_estimate'] = service.get_estimate_for_current_month rescue nil
        final_service_attributes << service_hash
      end
    end
    final_service_attributes
  }

  property :list_available_sgs
  property :available_sgs

  collection :environment_tags,
    class: EnvironmentTag,
    extend: EnvironmentTagRepresenter

  collection :environment_storages, as: :storages,
    class: Storage,
    extend: StorageRepresenter

  # link :download_private_key do |args|
  #   download_private_key_environment_path(id) if args[:options][:current_user].can_read?(self)
  # end

  def list_available_sgs
    vpcs = self.vpcs
    security_group_list = {}
    if vpcs
      vpcs.each do |vpc|
        security_groups = vpc.security_groups
        security_groups.each do |sg|
          security_group_list.merge!({sg.provider_id => sg.name})
        end
      end
    end
    security_group_list
  end


  def environment_storages
    clusters = self.storages
  end


  def available_sgs
    vpcs = self.vpcs
    security_group_list = {}
    if vpcs
      vpcs.each do |vpc|
        security_groups = vpc.security_groups
        security_groups.each do |sg|
          security_group_list.merge!({sg.id => {"name" => sg.name, "provider_id" => sg.provider_id}})
        end
      end
    end
    security_group_list
  end
end
