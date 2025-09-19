class RouteTables::Rules < CloudStreetService
  class << self

    def associate_route_table(route_table, route_details, &block)
      route_table = fetch RouteTable, route_table

      # Input Params == RouteTableId, SubnetId
      associate_dissassociate_rt(route_table, :associate_route_table, route_details, &block)
    end

    def disassociate_route_table(route_table, route_details, &block)
      route_table = fetch RouteTable, route_table

      # Input Params == AssociationId
      associate_dissassociate_rt(route_table, :disassociate_route_table, route_details, &block)
    end

    def associate_dissassociate_rt(route_table, method_name, options, &block)
      begin
        if method_name.to_s.eql?("associate_route_table")
          attach_route_table(route_table, method_name, options)
        elsif method_name.to_s.eql?("disassociate_route_table")
          detach_route_table(route_table, method_name, options)
        end
      rescue => error
        if error.class.to_s.include? 'Fog'
          status Status, :fog_error, error, &block
          return
        else
          raise error
        end
      end
      updated_rt = sync_with_aws(route_table) # need to sync with aws because aws is not returning updated security_group

      # Update service table when ever any association is made or removed
      updated_rt = update_service(route_table)

      status Status, :success, route_table, &block
      updated_rt
    end

    def attach_route_table(route_table, method_name, options)
      route_table_id = options[:route_table_id]
      subnet_id = options[:subnet_id]
      remote_rt = route_table.is_a?(Fog::Compute::AWS::RouteTable) ? route_table : remote_route_table(route_table)
      route_table.aws_compute_agent.send method_name, route_table_id, subnet_id
    end

    def detach_route_table(route_table, method_name, options)
      association_id = options[:association_id]
      remote_rt = route_table.is_a?(Fog::Compute::AWS::RouteTable) ? route_table : remote_route_table(route_table)

      route_table.aws_compute_agent.send method_name, association_id
    end

    def create_route(route_table, route_details, &block)
      route_table = fetch RouteTable, route_table
      route_table.extend(Validatables::Services::Network::RouteTable::AWS)
      route_table.validate_route(route_details)
      if route_table.errors.any?
        status Status, :validation_error, route_table.errors.first.last, &block
        return
      end
      route_table = route_table.class.find route_table.id
      # Input Params == RouteTableId, DestinationCidrBlock, GatewayId/ InstanceId/ NetworkInterfaceId
      add_delete_route_in_route_table(route_table, :create_route, route_details, &block)
    end

    def delete_route(route_table, route_details, &block)
      route_table = fetch RouteTable, route_table

      # Input Params == RouteTableId, DestinationCidrBlock
      add_delete_route_in_route_table(route_table, :delete_route, route_details, &block)
    end

    def add_delete_route_in_route_table(route_table, method_name, options, &block)
      begin
        if method_name.to_s.eql?("create_route")
          add_route(route_table, method_name, options)
        elsif method_name.to_s.eql?("delete_route")
          remove_route(route_table, method_name, options)
        end
      rescue => error
        if error.class.to_s.include? 'Fog'
          status Status, :fog_error, error, &block
          return
        else
          raise error
        end
      end
      remote_rt = remote_route_table(route_table)
      sync_with_aws(route_table, remote_rt) # need to sync with aws because aws is not returning updated route_table
      if route_table.is_a?(::RouteTables::AWS)
        Services::Network::RouteTable::AWS.update_routes_from_remote(route_table, remote_rt)
      end

      status Status, :success, route_table, &block
      route_table
    end

    def sync_with_aws(route_table, remote_rt=nil)
      remote_rt = remote_route_table(route_table) if remote_rt.blank?
      updated_rt = route_table.update({
        name:         remote_rt.tags['Name'],
        provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_rt),
        routes:       remote_rt.routes || [],
        associations: remote_rt.associations || [],
        tags: remote_rt.tags
      })
      return updated_rt
    end

    def update_service(route_table)
      remote_rt = remote_route_table(route_table)
      service = Service.where(provider_id: route_table.provider_id).last
      unless service.blank?
        updated_rt = service.update(
          provider_id:    remote_rt.id,
          name:           remote_rt.tags['Name'] || 'main',
          provider_data:  ProviderWrappers::AWS.parse_remote_service(remote_rt),
          routes:       remote_rt.routes || [],
          associations: remote_rt.associations || [],
          tags: remote_rt.tags
        )
      end
      return updated_rt
    end

    def add_route(route_table, method_name, options)
      route_table_id = options[:route_table_id]
      destination_cidr_block = options[:destination_cidr_block]
      internet_gateway_id = nil
      instance_id = nil
      if options[:internet_gateway_id][0..2] == 'igw'
        internet_gateway_id = options[:internet_gateway_id]
      else
        instance_id = options[:internet_gateway_id]
      end

      # create_route(route_table_id, destination_cidr_block, internet_gateway_id=nil, instance_id=nil, network_interface_id=nil
      route_table.aws_compute_agent.send method_name, route_table_id, destination_cidr_block, internet_gateway_id, instance_id
    end

    def remove_route(route_table, method_name, options)
      route_table_id = options[:route_table_id]
      destination_cidr_block = options[:destination_cidr_block]

      route_table.aws_compute_agent.send method_name, route_table_id, destination_cidr_block
    end

    def remote_route_table(route_table)
      route_table.aws_compute_agent.route_tables.get(route_table.provider_id)
    end
  end
end
