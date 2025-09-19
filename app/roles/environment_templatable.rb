class EnvironmentTemplatable
  include Behaviors::ReusableServicesUpdatable

  AUTO_INCEMENT_SERVICES =  ["Services::Vpc", "Services::Network::LoadBalancer::AWS", "Services::Network::Subnet::AWS", "Services::Compute::Server::AWS", "Services::Compute::Server::Volume::AWS", "Services::Network::RouteTable::AWS", "Services::Network::SecurityGroup::AWS", "Services::Network::SubnetGroup::AWS", "Services::Network::AutoScaling::AWS", "Services::Network::AutoScalingConfiguration::AWS", "Services::Database::Rds::AWS", "Services::Compute::Server::IscsiVolume::AWS"]  
  RESUABLE_CLASS_MAP  = {'Services::Network::SecurityGroup::AWS' =>'SecurityGroup', "Services::Network::Subnet::AWS" => 'Subnet', "Services::Network::SubnetGroup::AWS" => 'SubnetGroup', 'Services::Vpc' => 'Vpc'}

  class << self
    def create_from_template(template, user, tenant, organisation, name, tags, selected_type, adapter_id)
      namez = name ? name : template.name
      account = organisation.account
      user_role_ids =  if user.user_roles.pluck(:name).include? 'CloudStreetMarketplaceAMIAdmin'
        []
      else
        provisioned_user_roles = organisation.roles.where(provision_right: true).pluck(:id)
        tenant.get_user_roles(user.id).pluck(:id) + provisioned_user_roles
      end
      e = Environment.new.tap do |environment|
        environment.id                = SecureRandom.hex
        environment.name              = namez
        environment.template          = template
        # environment.account           = template.account
        environment.friendly_id       = SecureRandom.hex(4)
        environment.region_id         = template.region_id
        environment.environment_model = template.template_model
        environment.user_role_ids     = user_role_ids.uniq
        environment.data =  {'restricted' => false }
        environment.data = {'restricted' => true } if environment.user_role_ids != []
        environment.data_will_change!
        # GT is not specific to account, not keeping id in it.
        # While provisionig to any account then we associate user's account to environment.
        environment.account = if template.generic_type?
                                organisation.account
                              else
                                template.account
                              end
      end
      return e unless e.save
      # Create services and interfaces
      services, services_and_associates, services_map  = dup_services_n_interfaces(template, account ,e, user, tags, selected_type, adapter_id)

      # Now create connections between interfaces
      dup_connections(e, services_and_associates, services_map)
      Behaviors::ReusableServicesUpdatable.set_reusable_service { e.services }
      # update_hostname_to_volume(e.services) if e.account.naming_convention_enabled?
      update_hostname_to_volume(e, e.services, user, tags) if e.account.naming_convention_enabled?
      perform_auto_increment(e, user)
      e
    end

    def perform_auto_increment(environment, user)
      return if !environment.account.ip_auto_increment_enabled? || environment.template.privateip_exception
      environment.services.each { |s| s.auto_incerement! }
    end

    def get_parsed_name(raw_name, provision_tags)
      return raw_name if provision_tags.blank?
      str_t = raw_name[/#{Regexp.escape('$$')}(.*?)[a-zA-Z_]*/]
      if str_t
        CSLogger.info "str_t: #{str_t.inspect}"
        tag_sliced = str_t.remove('$$')
        CSLogger.info "tag_sliced: #{tag_sliced}"
        selected_tag = provision_tags.select{|tag| tag['tag_key'].downcase.parameterize(separator: '_') == tag_sliced}
        puts "selected_tag: #{selected_tag}"
        if selected_tag.present?
          tag_value = selected_tag.first.fetch('tag_value')
          puts "tag_value: #{tag_value}"
          replacement_tag_value = tag_value
          raw_name.gsub!(str_t, replacement_tag_value)
          get_parsed_name(raw_name, provision_tags)
          return raw_name
        else
          return raw_name
        end
      else
        return raw_name
      end
    end

    def check_if_sg_exists(s_service)
      account_id = s_service.account_id
      region_id = s_service.region_id
      adapter_id = s_service.adapter_id
      vpc_provider_id = s_service.vpc_id
      s_group_id = s_service.group_id
      uniq_id = s_service.uniq_provider_id
      if uniq_id.blank? && s_group_id
        SecurityGroup.by_group_id(adapter_id, account_id, region_id, vpc_provider_id, s_group_id)
      elsif s_group_id.blank? && uniq_id
        SecurityGroup.by_uniq_id(adapter_id, account_id, region_id, vpc_provider_id, uniq_id)
      elsif uniq_id && s_group_id
        SecurityGroup.by_group_id(adapter_id, account_id, region_id, vpc_provider_id, s_group_id)
      end
    end

    def check_if_sgroup_exists(sg_service)
      account_id = sg_service.account_id
      region_id = sg_service.region_id
      adapter_id = sg_service.adapter_id
      vpc_provider_id = sg_service.vpc_id
      sg_group_id = sg_service.provider_id
      uniq_id = sg_service.uniq_provider_id
      if uniq_id.blank? && sg_group_id
        SubnetGroup.by_provider_id(adapter_id, account_id, region_id, vpc_provider_id, sg_group_id)
      elsif sg_group_id.blank? && uniq_id
        SubnetGroup.by_uniq_id(adapter_id, account_id, region_id, vpc_provider_id, uniq_id)
      elsif uniq_id && sg_group_id
        SubnetGroup.by_provider_id(adapter_id, account_id, region_id, vpc_provider_id, sg_group_id)
      end
    end

    def dup_services_n_interfaces(template, account, environment, user, tags, selected_type, adapter_id)
      services = template.services
      naming_convention_enabled = template.with_nc
      # eip_templated_ids =  services.network_interfaces.first.private_ips.collect {|private_ips| private_ips['elasticIp']}.select(&:presence)
      eip_ids_map ||={}
      server_map ||= {}
      env_template_cost = environment.get_template_cost
      environment_services = []
      servers_with_filer_volumes = []
      # services_and_associates => Contains the each service and their interfaces with connections
      services_and_associates = Hash.new
      # services_map => Mapping new services with old services, it will required when we need to set remote interface.
      services_map = {}
      services.each_with_index do |s, index|
        new_service = s.dup
        # GT: Changing Generic Service to Service.
        new_service = convert_generic_service_to_original(new_service, adapter_id, account.id)
        new_service.id = SecureRandom.uuid
        sg_already_exists = check_if_sg_exists(new_service) if s.type == "Services::Network::SecurityGroup::AWS"
        sggroup_already_exists = check_if_sgroup_exists(new_service) if s.type == "Services::Network::SubnetGroup::AWS"
        server_map.merge!(s.id => new_service.id) if s.type == "Services::Compute::Server::AWS"
        puts "server_map=#{server_map.inspect}"
        new_service.data = {} if new_service.data.nil?
        new_service.data['selected_type'] = selected_type
        if new_service.is_elastic_ip?
          eip_ids_map.merge!(s.id => new_service.id)
        end
        # GT: We are skipping this step, as we need VPCs interfaces and connections so need to skip state.
        new_service.state = "environment" if (new_service.is_vpc? && !new_service.provider_id && !new_service.class.name.include?('Generic'))
        puts "----------eip_ids_map-----#{eip_ids_map.inspect}"        
        if naming_convention_enabled && ( !environment.template.naming_exception ) && AUTO_INCEMENT_SERVICES.include?(new_service.type) 
          if s.type == "Services::Database::Rds::AWS" || s.type == "Services::Database::Generic::Rds::AWS"
            service_type = CommonConstants::SERVICE_TYPE_MAP[new_service.type][new_service.engine]
            nc_params =  {'service_type' => service_type, 'provisioned_tags' => tags}
            nc_params.merge!(CloudStreetService.get_environment_params(environment))
            new_service.name = new_service.class.get_parsed_service_name(account, user, new_service.name, new_service.class, nc_params, new_service)
          elsif s.type == "Services::Network::SecurityGroup::AWS" && s.default && !s.name.include?('#')
            new_service.name = s.name
          elsif s.type == "Services::Network::SecurityGroup::AWS" && s.default && sg_already_exists && s.name.include?('#')
            new_service.name = sg_already_exists.name || s.name
          elsif s.type == "Services::Network::SecurityGroup::AWS" && !s.default && sg_already_exists && sg_already_exists.state.eql?('available') && s.name.include?('#')
            new_service.name = sg_already_exists.name || s.name
          elsif s.type == "Services::Network::SecurityGroup::AWS" && !s.default && sg_already_exists && !s.name.include?('#')
            new_service.name = s.name
          elsif s.type == "Services::Network::SubnetGroup::AWS" && sggroup_already_exists && !s.name.include?('#')
            new_service.name = s.name.downcase
          elsif s.type == "Services::Network::RouteTable::AWS" && s.main && !s.name.include?('#')
            new_service.name = s.name
          elsif s.type == "Services::Network::RouteTable::AWS" && s.main && s.name.include?('#')
            new_service.name = "main" #till we implement workflow for route table
          elsif s.type == "Services::Network::Subnet::AWS" && !s.get_same_subnet_services.select{|subnet| subnet.state.eql?('running')}.first.blank?
            new_service.name = s.get_same_subnet_services.select{|subnet| subnet.state.eql?('running')}.first.name
          elsif s.type == "Services::Compute::Server::Volume::AWS"
            new_service.name = s.name
          else
            service_type = CommonConstants::SERVICE_TYPE_MAP[new_service.type]
            nc_params = {'service_type' => service_type, 'provisioned_tags' => tags}
            nc_params.merge!(CloudStreetService.get_environment_params(environment))
            if RESUABLE_CLASS_MAP.keys.include?(new_service.class.to_s)
              klass = RESUABLE_CLASS_MAP[new_service.class.to_s]
              new_service_name = klass.eql?('SubnetGroup') ? new_service.name.downcase : new_service.name
              new_service.name = new_service.class.get_parsed_service_name(account, user, new_service_name, klass, nc_params, new_service)
              if new_service.is_subnet_group? && sggroup_already_exists && sggroup_already_exists.name.exclude?('#') && ((sggroup_already_exists.provider_id && sggroup_already_exists.provider_id.eql?(new_service.provider_id)) || (sggroup_already_exists && sggroup_already_exists.data['uniq_provider_id'].eql?(new_service.data['uniq_provider_id'])))
                new_service.name = sggroup_already_exists.name
              end
              CSLogger.info "Resuable new_service name #{new_service.name}"
            else
              new_service.name = new_service.class.get_parsed_service_name(account, user, new_service.name, new_service.class, nc_params, new_service)
            end
          end
          new_service.name = new_service.name + new_service.data['name_free_text'] if new_service.data['name_free_text']

          if new_service.is_autoscaling? && !new_service.policies.blank?
            asg_naming_convention = environment.account.service_naming_defaults.auto_scaling.first.prefix_service_name
            policies = new_service.policies
            parsed_names_policies = policies.inject([]) do |parsed_names_policies, policies_hash|
              policies_hash['id'] = policies_hash['id'].gsub(/#{asg_naming_convention}/, new_service.name)
              policies_hash['alarm'] = policies_hash['alarm'].gsub(/#{asg_naming_convention}/, new_service.name)
              parsed_names_policies << policies_hash
            end
            new_service.policies = parsed_names_policies
            new_service.data_will_change!
            new_service.save!
          end
        end

        Behaviors::ReusableServicesUpdatable.update_reusable_service_with_its_dependencies_for_name(new_service)
        if new_service.is_server? && new_service.filer_volumes.present?
          servers_with_filer_volumes << new_service
        end
        # Interface array
        interfaces = []
        s.interfaces.each do |i|
          # new_interface = ObjectCopier.new(i).copy
          new_interface = i.dup
          new_interface.id = SecureRandom.uuid  
          new_service.interfaces << new_interface
          interfaces << { new_interface => i }
        end

        new_service.user = user

        new_service.cost_by_hour =  new_service.compute_hourly_cost(env_template_cost) if Service::BILLABLE_SERVICES.include? new_service.type

        new_service.environmented! unless new_service.state == "environment"


        create_cluster_for_aurora(new_service, environment)
        # CSLogger.info ": Cluster at Enviroment Pending---------------------------#{cluster.id}" if cluster
        environment.services << new_service
        # GT: We are keeping services hash so we can get original interface(Old) for new interface and can dup its connection
        # We will not require ObjectCopier, as it only associated the object on object_id and when we query it we will loss it.
        services_and_associates[new_service.id] = { 'interfaces' => interfaces, 'type' => s.type }
        #GT: { 'new_service' => 'old_service' }
        services_map[new_service.id] = s.id

        # environment_services << {id: SecureRandom.hex, environment_id: environment.id, service_id: new_service.id}
      end
      # EnvironmentService.import(environment_services)
      Behaviors::ReusableServicesUpdatable.set_reusable_service { environment.services }

      link_filer_volumes_to_environment(servers_with_filer_volumes, environment)
      eni_default_templated = environment.services.select {|d| d.type == "Services::Network::NetworkInterface::AWS"}# all enis      

      return [environment.services, services_and_associates, services_map] if eni_default_templated.nil?

      eni_default_templated.each do |eni_default|
        eni_default.private_ips.each do |pip_hash|
          eip_ids_map.each do |eip_old_id, eip_new_id|
            if pip_hash['elasticIp'] && pip_hash['elasticIp'].eql?(eip_old_id)
              pip_hash['elasticIp'] = eip_new_id
            end
          end
        end
        eni_default.data_will_change!
        eni_default.save!
      end
      update_connection_service_id(environment, server_map) if server_map.present?

      if environment.template.generic_type? # or check for vpc_id should be blank then execute
        environment.services.update_all(vpc_id: environment.services.vpcs.first.get_vpc_by_uniq_provider_id.id) #TODO when existing
      end
      # We need services_and_associates to dup interface's connections
      [environment.services, services_and_associates, services_map]
    end

    def link_filer_volumes_to_environment(servers_with_filer_volumes, environment)
      filer_volume_ids = []
      instance_filer_volumes = []
      environment_filer_volumes = []

      servers_with_filer_volumes.each do|server|
        server.filer_volumes.each do|volume|
          filer_volume_ids << volume["filer_volume_id"]
          instance_filer_volumes << {id: SecureRandom.hex, filer_volume_id: volume["filer_volume_id"], service_id: server.id}
        end
      end

      filer_volume_ids.uniq.each do|volume_id|
        environment_filer_volumes << {id: SecureRandom.hex, environment_id: environment.id, filer_volume_id: volume_id}
      end

      InstanceFilerVolume.import(instance_filer_volumes)
      EnvironmentFilerVolumes.import(environment_filer_volumes)
    end

    def get_environment_params(environment)
      env_name = environment.name
      temprev = environment.template.revision.to_s rescue ''
      tempname = environment.template.name rescue ''
      {
        'templatename' => tempname,
        'environmentname' => env_name,
        'templaterevision' => temprev
      }
    end

    def update_hostname_to_volume(environment, eservices, user, tags)
      nc_params = {'service_type' => 'Volume', 'provisioned_tags' => tags}
      nc_params.merge!(CloudStreetService.get_environment_params(environment))
      eservices.each do |eservice|
        if eservice.is_server? && eservice.interfaces.where(interface_type: "Protocols::Disk").first
          attached_volumes = []
          eservice.interfaces.where(interface_type: "Protocols::Disk").first.connections.each do |connection|
            attached_volumes << connection.remote_interface.service
          end
          attached_volumes.each do |attached_volume|
            nc_params.merge!({'service_id' => attached_volume.id})
            CSLogger.info "attached_volume.name=#{attached_volume.name}-=-=nc_params=#{nc_params}-=-attached_volume.class=#{attached_volume.class}"
            attached_volume.name = attached_volume.class.get_parsed_service_name(environment.account, user, attached_volume.name, attached_volume.class, nc_params, attached_volume)
            CSLogger.info "inside update_hostname_to_volume-=-attached_volume.name=#{attached_volume.name}"
            attached_volume.save!
          end
        elsif eservice.is_autoscaling_configuration?
          parsed_volumes = eservice.get_parsed_volume_name
          eservice.block_device_mappings = parsed_volumes
          eservice.data_will_change!
          eservice.save!
        end
      end
    end

    def create_cluster_for_aurora(new_service, environment)
      return unless new_service.type == "Services::Database::Rds::AWS" && new_service.engine.eql?('aurora')
      new_service.cluster_id = new_service.cluster_id.try(:downcase).blank? ? "#{new_service.name.try(:downcase)}-cluster" : new_service.cluster_id.try(:downcase)
      new_service.data_will_change!
      new_service.save!
      existing_cluster = Cluster.by_account_region_provider_id(environment.account_id, environment.region_id, new_service.cluster_id).first
      if existing_cluster.nil?
        basic_cluster_attrs = get_basic_cluster_attrs(new_service, environment)
        CSLogger.info "basic_cluster_attrs: #{basic_cluster_attrs.inspect}"
        basic_cluster = Cluster.new(basic_cluster_attrs)
        basic_cluster.save!
        basic_cluster
      else
        existing_cluster
      end
    end

    def get_basic_cluster_attrs(new_service, environment)
      provider_id = new_service.cluster_id.blank? ? "#{new_service.name.try(:downcase)}-cluster" : new_service.cluster_id
      attrs = {
        backup_retention_period:      new_service.backup_retention_period,
        db_cluster_members:           [],
        db_cluster_parameter_group:   'default.aurora5.6',
        db_subnet_group:              "default",
        endpoint:                     '',
        engine:                       'aurora',
        engine_version:               '5.6.10a',
        port:                         '3306',
        preferred_backup_window:      new_service.get_preferred_backup_window,
        preferred_maintenance_window: new_service.get_preferred_maintenance_window,
        state:                        'pending',
        vpc_security_groups:          [],
        type:                         'Clusters::AWS',
        account_id:                   environment.account_id,
        region_id:                    environment.region_id,
        provider_data:                nil
      }
      attrs.merge!(provider_id: provider_id)
    end

    def update_connection_service_id(environment, server_map)
      environment.services.route_tables.each do |route_table|
        next if route_table.is_main?
        if route_table.additional_route_properties.present? || route_table.routes
          routes = route_table.routes
          new_routes = routes.inject([]) do |new_routes, route|
            if route['connected_service_id'].present? && server_map.present? && server_map.keys.include?(route['connected_service_id'])
              route['connected_service_id'] = server_map[route['connected_service_id']]
              CSLogger.info  "route=#{route.inspect}"
            end
            new_routes.push(route)
          end
          route_table.routes = new_routes if new_routes.present?
        end
        route_table.data_will_change!
        route_table.save
        route_table.additional_properties_will_change!
        route_table.set_additional_properties!
        route_table.save!
      end
    end

    def dup_connections(environment, services_and_associates, services_map)
      environment.services.uniq.each do |s|
        interfaces = services_and_associates[s.id]['interfaces']
        interfaces.each_with_index do |i, ids|
          i.values[0].connections.each do |c|
            new_connection = c.dup
            new_connection.id = SecureRandom.uuid
            ri_id = c.remote_interface.id if c.remote_interface
            blah = nil
            blah = get_remote_interface_id(services_and_associates, c)
            new_connection.remote_interface = blah
            i.keys[0].connections << new_connection
          end
        end
        s.additional_properties_will_change!
        s.set_additional_properties!
        s.save!
      end
    end

    def get_remote_interface_id(services_and_associates, c)
      blah = nil
      services_and_associates.values.each do |sa|
        sa['interfaces'].each do |interface|
          blah = interface.invert[c.remote_interface] if interface.invert[c.remote_interface].present?
        end
      end
      blah
    end

    def create_sync_services_from_params(environment, params)
      created_at = updated_at = Time.now
      selected_type = params[:selected_type].nil? ? 2 : params[:selected_type]
      service_vpc_id = SecureRandom.hex
      vpc_id = nil
      service_id_map    = {} # map of service ids e.g service_id_map[old_id] = new_id
      interface_id_map  = {} # same as ^
      connection_id_map = {} # same as ^
      server_map = {}
      eip_ids_map = {}
      start_time = Time.now
      services = Service.includes(:interfaces).includes(:connections).where(id: params[:services].collect{|service_hash|service_hash['id']}).all
      service_attrs_list = []
      env_service_list = []
      services.each do |s|
        service                       = s.dup
        service.id                    = (service.is_vpc? ? service_vpc_id : SecureRandom.uuid)
        # service.sync_service_id       = s[:id]
        service.service_vpc_id        = service_vpc_id
        # service.selected_type         = selected_type
        service.last_cost_update_time = Time.now
        service.hourly_cost           = 0
        if service.is_server?
          server_map.merge!(s[:id] => service.id)
          created_time = service.created_time ? service.created_time.to_time : Time.now
          service.parsed_data.merge!(start_time: created_time, up_time: ((Time.now - created_time)/3600).ceil)
        end
        service.data = service.parsed_data.merge({ sync_service_id: s[:id], selected_type: selected_type })
        service.data = service.data
        # service.data_will_change!
        service.created_at = created_at
        service.updated_at = updated_at
        service_attrs_list.push(service.attributes)
        eip_ids_map.merge!(s[:id] => service.id) if s[:type] == "Services::Network::ElasticIP::AWS"
        service_id_map[s[:id]] = service.id
        vpc_id  = service.vpc_id if service.is_subnet? && vpc_id.blank?
        env_service_list.push({environment_id:  environment.id, service_id: service.id})
      end
      Service.import(service_attrs_list)
      EnvironmentService.create(env_service_list)
      vpc = services.vpcs.first
      vpc_id = vpc.vpc.id unless vpc.blank?
      EnvironmentVpc.create(environment_id: environment.id, vpc_id: vpc_id)
      # Interfaces
      interfaces = []
      services.each do |s|
        #TODO copy service ids DEV-2548
        s.interfaces.each do |i|
          interface_id_map[i[:id]]=SecureRandom.uuid
          interfaces.push({
            id: interface_id_map[i[:id]],
            name: i[:name],
            depends: i[:depends],
            interface_type: i[:interface_type],
            service_id: service_id_map[i.service_id],
            created_at: created_at,
            updated_at: updated_at
          })
        end
      end
      Interface.import(interfaces)

      connections = []
      services.each do |s|
        #TODO copy service ids DEV-2548
        s.interfaces.each do |i|
          i.connections.each do |c|
            connections.push({
              id: SecureRandom.uuid,
              interface_id: interface_id_map[c.interface_id],
              remote_interface_id: interface_id_map[c.remote_interface_id],
              created_at: created_at,
              updated_at: updated_at
            })
          end
        end
      end
      Connection.import(connections)
      update_connection_service_id(environment, server_map) if server_map.present?
      environment.services.reload.network_interfaces.each do |nic|
        nic.private_ips.each do |pip_hash|
          pip_hash["elasticIp"] = eip_ids_map[pip_hash["elasticIp"]] if pip_hash["elasticIp"] && eip_ids_map.has_key?(pip_hash["elasticIp"])
        end
        # nic.private_ips = nic.private_ips.collect do |pip_hash|
        #   CloudStreet.log "pip_hash----- #{pip_hash}"
        #   eip_ids_map.each do |eip_old_id, eip_new_id|
        #     CloudStreet.log "eip_old_id--- #{eip_old_id}----eip_new_id----- #{eip_new_id}"
        #     if pip_hash["elasticIp"] && pip_hash["elasticIp"].eql?(eip_old_id)
        #       pip_hash["elasticIp"] = eip_new_id
        #     end
        #     CSLogger.info "pip_hash-- #{pip_hash}"
        #     pip_hash
        #   end
        # end
        nic.data_will_change!
        nic.save!
      end
    end

    def convert_generic_service_to_original(new_service, adapter_id, account_id)
      new_service.type = new_service.type.gsub('::Generic', '')
      new_service.generic_type = new_service.generic_type.gsub('::AWS', '')
      new_service.adapter_id = adapter_id if new_service.adapter_id.nil?
      new_service.account_id = account_id if new_service.account_id.nil?
      new_service
    end
  end
end
