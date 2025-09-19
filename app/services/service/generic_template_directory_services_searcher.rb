class Service::GenericTemplateDirectoryServicesSearcher < CloudStreetService
  SERVICE_DATA_VALIDATIONS_TO_SKIP = ["Generic::Services::Vpc","Generic::Services::Network::AvailabilityZone","Generic::Services::Internet","Generic::Services::NewRelic", 'Generic::Services::Network::Subnet', 'Generic::Services::Compute::Server']
  def initialize(user, account, generic_directory_service_params)
    @user = user
    @account = account
    @region  = fetch Region, generic_directory_service_params['region_id']
    @vpc_id  = generic_directory_service_params['vpc_id']
  end

  def search(&block)
    yield Status.error("Please select region") and return if @region.blank?
    @common_template_directory_services = Service.generic_template_directory.by_provider("Providers::AWS")
    @common_template_directory_services = @common_template_directory_services.where.not(type: ["GenericService::Services::Compute::Server::Volume::AWS", "GenericService::Services::Compute::Server::IscsiVolume::AWS"]) if @is_unallocated
    final_directory_services = @common_template_directory_services.map { |service|
      service.region = @region
      ServiceDirectoryInfo.new service, @user
    }
    final_directory_services.uniq! {|e| e.generic_type }
    # Currently we are creating new VPC, later used it based on Region
    # @vpcs ||= Vpc.available_vpc_by_region(@region)
    searched_services = vpc_services + rds_region_services + availability_zone_services + ami_services  + route_table_services + load_balancer_services  + filer_volumes
    services = searched_services.map { |service|
      next if service.blank?
      service.region = @region
      ServiceDirectoryInfo.new service, @user
    }
    yield Status.success(services + final_directory_services)
    return
  end

  # There will be always new VPC so returning with region
  def vpc_services
    # return [] unless @adapter.have_service? Services::Vpc
    directory_vpc_service = Service.directory.where(type: 'Services::Generic::Vpc').first
    return [] if directory_vpc_service.blank?
    directory_vpc_service.region = @region
    # # vpcs = Services::Vpc.fetch_vpc_by_access(@region.id, @user)
    # # vpcs = Vpc.where(region_id: @region.id)
    # vpcs = vpcs.where(vpc_id: @vpc_id) if @vpc_id.present?
    # object_copier directory_vpc_service, vpcs, name: :name, vpc_id: :vpc_id, cidr_block: :cidr, primary_key: :id, internet_attached: :internet_attached, internet_gateway_id: :get_ig_provider_id, enable_dns_resolution: :enable_dns_resolution, enable_dns_hostnames: :enable_dns_hostnames
    [directory_vpc_service]
  end

  def filer_volumes
    # return [] if @is_unallocated
    filer_objects = []
    return [] unless @account.cloud_resource_adapters.present?
    ['NFS', 'CIFS'].each do |filer_volume_type|
      filer_objects << InstanceFiler.new("#{filer_volume_type} volume", filer_volume_type)
    end
    filer_objects    
  end

  # fetch list of availability zones which are available in given adapter & region
  # and prepare list of these AvailabilityZone-services
  def availability_zone_services
    # return [] unless @adapter.have_service? Services::Network::AvailabilityZone
    directory_az_service = Service.directory.where(type: 'Services::Network::Generic::AvailabilityZone').first
    return [] if directory_az_service.blank?
    directory_az_service.region = @region
    # directory_az_service.adapter = @adapter
    directory_az_service.set_az_codes
    [directory_az_service]
  end

  def ami_services
    # return [] unless @adapter.have_service? Services::Compute::Server
    directory_ami_service, amis = Services::Compute::Generic::Server::AWS.fetch_accessible_amis(@account.id, @region.id, @user)
    # directory_ami_service.adapter_id = @adapter.id
    return [] if directory_ami_service.blank?
    directory_ami_service.region_id = @region.id
    object_copier(directory_ami_service, amis, {name: :image_name, image_id: :image_id, instance_types: :instance_types, virtualization_type: :virtualization_type, platform: :platform, root_device_type: :root_device_type, iam_role: :iam_role, associate_public_ip: :associate_public_ip, block_device_mappings: :block_device_mappings, ebs_optimized: :ebs_optimized, instance_monitoring: :instance_monitoring, active: :active, root_device_name: :root_device_name})
  end

  def server_services
    return [] if @is_unallocated
    server_services = Service.where(account: @account.id, region_id: @region.id, generic_type: 'Services::Compute::Generic::Server::AWS').where.not(state: 'directory')
    environmented_servers = server_services.select { |s| s.is_environmented_and_not_deleted? }
    synced_servers = server_services.select { |s| s.is_synced_service? }
    uniq_servers_map = (environmented_servers + synced_servers).inject({}) do |server_map, server|
      next(server_map) if server_map[server.private_ip_address].present?
      server_map[server.private_ip_address] = server
      server_map
    end
    server_services
  end

  def fetch_services_data
    services = Service
               .generic_services
               .where(account: @account.id, region_id: @region.id)
               .where.not(state: 'directory',generic_type: SERVICE_DATA_VALIDATIONS_TO_SKIP)
    services + server_services
  end

  def fetch_templates_data
    Template.select(:id, :name).where(account: @account.id, generic_type: true).unarchived
  end

  def rds_region_services
    return [] if @is_unallocated
    rds_services = get_region_based_rds
    account_based_rds = filter_rds(rds_services)
    account_based_rds.each do |rds|
      rds.directory_region = @region.code
    end
  end

  def get_region_based_rds
    allowed_regions = CommonConstants::REGIONS - ["ap-southeast-1", "sa-east-1"]
    if allowed_regions.include?(@region.code)
      Service.directory.where(type: 'Services::Database::Generic::Rds::AWS')
    else
      Service.directory.where(type: 'Services::Database::Generic::Rds::AWS').where("data ->>'engine' != ?", 'aurora')
    end    
  end

  def get_rds_params
    params = {}
    RdsConfigService::DATABASES.each do |rds|
      params.merge!(rds => {"-1" => []})
    end
    params
  end

  def build_association
    data = get_rds_params
    @account.build_rds_configuration(data: data, updated_by: @user, created_by: @user)  
    @account.save
    @account.rds_configuration    
  end

  def load_balancer_services
    lb_services = Service.directory.where(type: 'Services::Network::Generic::LoadBalancer::AWS')
  end

  def filter_rds(rds_services)
    rds_configs = (@account.rds_configuration.nil? ? build_association : @account.rds_configuration)
    everyone_allowed = rds_configs.data.select {|k,v| v["-1"]}.keys.collect {|key| key.gsub('_','-')}
    user_roles = @user.user_roles.pluck(:id)
    specific_engine_allowed = rds_configs.data.collect{|k,v| k.gsub('_','-') if !(v.keys & user_roles).empty? } if rds_configs.data
    all_rds_allowed = everyone_allowed + specific_engine_allowed
    rds_services.where("data ->> 'engine' IN (?) ", all_rds_allowed.dup.uniq)
  end

  def security_group_services
    # return [] unless @adapter.have_service? Services::Network::SecurityGroup
    security_group_collection = @vpcs.map { |vpc| vpc.security_groups }.flatten
    security_group_service = Service.directory.where(type: 'Services::Network::Generic::SecurityGroup::AWS').first
    object_copier security_group_service, security_group_collection, name: :name, description: :description, ip_permissions: :ip_permissions, ip_permissions_egress: :ip_permissions_egress, default: :check_defualt_sg, local_vpc_id: :provider_vpc_id, group_id: :group_id, uniq_provider_id: :uniq_provider_id, vpc_id: :vpc_id
  end

  def subnet_group_services
    # return [] unless @adapter.have_service? Services::Network::SubnetGroup
    subnet_group_collection = @vpcs.map { |vpc| vpc.subnet_groups }.flatten
    subnet_group_service = GenericService.directory.where(type: 'Services::Network::Generic::SubnetGroup::AWS').first
    object_copier subnet_group_service, subnet_group_collection, name: :name, description: :description, subnet_ids:  :subnet_ids, status: :state, uniq_provider_id: :uniq_provider_id, subnet_service_ids:  :subnet_service_ids, provider_id: :provider_id, vpc_id: :vpc_id
  end

  def route_table_services
    # return [] unless @adapter.have_service? Services::Network::RouteTable
    # route_table_collection = @vpcs.map { |vpc| vpc.route_table }
    # route_table_service = Service.directory.where(type: 'Services::Network::Generic::RouteTable::AWS').first

    # object_copier route_table_service, route_table_collection, name: :name, route_table_id: :route_table_id, routes: :routes, associations: :associations, main: :present?, local_vpc_id: :provider_vpc_id
    # [route_table_service]
    []
  end

  # This method is born because sometimes we only want to copy some specific attributes
  # of source object while replicating it multiple times
  def object_copier(reference_obj, objs_to_be_copied, attr_to_be_copied={})
    objs_to_be_copied.map do |source_obj|
      reference_obj.dup.tap do |replica|
        attr_to_be_copied.each do |replica_obj_attr_name, source_obj_attr_name|
          new_value = if source_obj.kind_of? Hash
            source_obj[source_obj_attr_name]
            else
            source_obj.send source_obj_attr_name
          end
          replica.send "#{replica_obj_attr_name}=", new_value
        end
      end
    end
  end
end