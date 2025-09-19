class ProviderWrappers::AWS::Networks::RouteTable < ProviderWrappers::AWS
  def create_route(route_table_id, dest_cidr, ig_id, instance_id, network_interface_id)
    CSLogger.info "-------------------------create_route--------#{route_table_id}"
    agent.create_route(route_table_id, dest_cidr, ig_id, instance_id, network_interface_id)
  end

  def create_ig_route(route_table_id, dest_cidr, ig_id)
    CSLogger.info "-------------------------------Ig route wrapper params----#{ig_id}"
    agent.create_route(route_table_id, dest_cidr, ig_id)
  end

  def create_server_route(route_table_id, dest_cidr, instance_id)
    CSLogger.info "-------------------------------Instance route wrapper params----#{instance_id}"
    agent.create_route(route_table_id, dest_cidr, nil, instance_id)
  end

  def attach_subnet(route_table_id, subnets_provider_id)
    CSLogger.info "-----------------attach_subnet----#{route_table_id}----------#{subnets_provider_id}"
    agent.associate_route_table(route_table_id, subnets_provider_id)
  end

  def detach_subnet(association_id)
    CSLogger.info "-----------------detach_subnet--------#{association_id}"
    agent.disassociate_route_table(association_id)
  end

  def delete_route(route_table_id, dest_cidr)
    agent.delete_route(route_table_id, dest_cidr)
  end

  def replace_route(route_table_id, dest_cidr, options)
    agent.replace_route(route_table_id, dest_cidr, options)
  end

  def create_tags(route_table_id, tags_map)
    agent.create_tags(route_table_id, tags_map)
  end

  class << self
    def all(agent, filters = {})      
      options = {}
      options.merge!({'vpc-id' => filters[:vpc_id]}) if filters[:vpc_id].present?
      options.merge!({'route-table-id' => filters[:provider_ids]}) if filters[:provider_ids].present?
      options.merge!({'association.main' => filters[:main]}) if filters[:main].present?
      retry_on_timeout {
        return agent.route_tables.all(options)
      }
    end
  end
end
