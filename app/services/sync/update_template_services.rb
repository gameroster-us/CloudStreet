class Sync::UpdateTemplateServices
  SERVICE_FILE_MAP = {
    "Services::Vpc" => 'vpc.yml',
    "Services::Network::InternetGateway::AWS" => 'internet_gateway.yml',
    "Services::Network::RouteTable::AWS" => 'route_table.yml',
    "Services::Network::Subnet::AWS" => 'subnet.yml',
    "Services::Network::Nacl::AWS" => 'nacl.yml',
    "Services::Network::SubnetGroup::AWS" => 'subnet_group.yml',
    "Services::Network::SecurityGroup::AWS" => 'security_group.yml',
    "Services::Network::AutoScaling::AWS" => 'auto_scaling.yml',
    "Services::Network::AutoScalingConfiguration::AWS" => 'auto_scaling_configuration.yml',
    "Services::Compute::Server::AWS" => 'server.yml',
    "Services::Compute::Server::Volume::AWS" => 'volume.yml',
    "Services::Network::NetworkInterface::AWS" => 'network_interface.yml',
    "Services::Network::ElasticIP::AWS" => 'elastic_ip.yml',
    "Services::Network::LoadBalancer::AWS" => 'load_balancer.yml',
    "Services::Snapshots::Volume::AWS" => 'volume_snapshot.yml',
    "Services::Snapshots::Rds::AWS" => 'rds_snapshot.yml',
    "Services::Database::Rds::AWS" => 'rds.yml',
    "Services::Network::AvailabilityZone" => 'internet_gateway.yml'
  }


  def self.update_services_in_template(template, services, adapter, region, account)
    parent_directory = "#{adapter.aws_account_id}-#{account.id}"
    region_directory = "#{parent_directory}/#{region.code}"
    template_cost = nil
    ::REDIS.with do |conn|
      template_cost = JSON.parse(conn.get("#{region.code}_cost"))
    end
    service_arr = []
    services.each_pair do |key, template_services|
      file_name = SERVICE_FILE_MAP[key]
      next if file_name.nil?
      parsed_services = YAML.load(File.open("#{region_directory}/#{file_name}"))
      next if parsed_services.blank?
      aws_provider_ids = parsed_services.pluck(:provider_id)
      template_services.each do |service|
        case key
        when "Services::Vpc"
          provider_id = service.vpc_id || ""
        when "Services::Network::InternetGateway::AWS"
          provider_id = service.internet_gateway_id || ""
        when "Services::Network::Subnet::AWS"
          subnet_id = service.additional_properties["existing_subnet"]
          provider_id = Subnet.find_by(id: subnet_id).try(:provider_id) if subnet_id.present?
        when "Services::Network::SubnetGroup::AWS", "Services::Network::SecurityGroup::AWS"
          provider_id = service.provider_id || ""
        else
          next
        end
        if aws_provider_ids.include?(provider_id)
          selected_service = parsed_services.select{ |s| s.provider_id.eql?(provider_id)}.first
          service.attributes = selected_service.get_attributes_for_service_table.except(:state)
          service.update_hourly_cost(template_cost)
          service_arr << service
        else
          unless service.additional_properties["existing_subnet"].blank?
            service.state = "removed_from_provider"
            service.save
          end
        end
      end
    end
    Service.import service_arr, on_duplicate_key_update: {conflict_target: [:id], columns: [:name, :state, :data, :provider_data]}
  rescue Errno::ENOENT => e
    CSLogger.error("#{e.message} YML file not found.")
  end

  def self.update_template_if_vpc_deleted(template, adapter)
    template_vpc = template.services.where(type: "Services::Vpc").first
    unless template_vpc.blank?
      #taken archived vpc, as vpc is first archived from the base table.
      vpc = Vpc.where(vpc_id: template_vpc.provider_id, state: 'archived', adapter_id: adapter.id).first
      Template.where(id: template.id).joins(:template_vpcs).where(template_vpcs: { vpc_id: vpc.id}).update_all(state: "unhealthy") unless vpc.blank?
    end
  end
end
