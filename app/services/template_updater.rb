require "./lib/node_manager.rb"
class TemplateUpdater < CloudStreetService
  include Behaviors::ReusableServicesUpdatable

  def self.update(organisation, template, params, user, options={}, &block)
    account = organisation.account
    user     = fetch User, user
    template = fetch Template, template
    rt_params ||={}
    #status Status, :unauthorized, template.id, &block and return unless user.can_update?(template)

    template.name = params[:name] if params[:name]
    unless template.valid?
      errors = template.errors.messages.merge(template_error: true)
      status Status, :validation_error, errors, &block
      return
    end

    unless options[:skip_validation]
      template_validator = nil # ruby and it's variable scopes :)
      ActiveRecord::Base.transaction do
        template_validator = Validators::TemplateValidator.new params, account, event: :template_updation
        template_validator.validate
        raise ActiveRecord::Rollback
      end
      if template_validator.any_error_found?
        status Status, :validation_error, template_validator.error_msgs, &block
        return
      end
    end

    ActiveRecord::Base.transaction do
      # Set the name
      template.name = params[:name] if params[:name]
      provision_tags = params[:provision_tags] if params["save_template_tags"]
      template.template_model = params[:template_model]
      unless template.valid?
        CSLogger.error "errors::"
        errors = template.errors.messages.merge(template_error: true)
        status Status, :validation_error, errors, &block
        return
      end

      revision_data = { services_data: {}, changed_services: [], connections: {} }
      services_data = revision_data[:services_data]
      any_new_service_created = false

      # service_name_count_map  = Service.get_last_used_name_per_type(account, provision_tags)
      # CSLogger.info "service_name_count_map: #{service_name_count_map}"
      # service_name_format_map = Service.get_naming_default_format_map(template, account, provision_tags)
      # CSLogger.info "service_name_format_map: #{service_name_format_map}"
      # Services
      params[:services].each do |s|
        klass = ActionController::Base.helpers.sanitize(s[:type])
        type = klass.safe_constantize rescue ''
        name = s[:name]
        if ["Services::Network::SecurityGroup", "Services::Network::Generic::SecurityGroup::AWS"].include?(s[:type])
         


          sg_group_id = ''
          uniq_id = ''
          s['properties'].each do |pro|
            sg_group_id = pro['value'] if pro['name'] == 'group_id'
            uniq_id = pro['value'] if pro['name'] == 'uniq_provider_id'
          end
          if uniq_id.blank? && sg_group_id
            existing_sg = SecurityGroup.by_group_id(params[:adapter_id], account.id, params[:region_id], s[:vpc_id], sg_group_id)
          elsif sg_group_id.blank? && uniq_id
            existing_sg = SecurityGroup.by_uniq_id(params[:adapter_id], account.id, params[:region_id], s[:vpc_id], uniq_id)
          end
          # existing_sg = SecurityGroup.find_by(adapter_id: params[:adapter_id], account_id: account.id, region_id: params[:region_id], vpc_id: s[:vpc_id], name: s[:name])
          if (s[:name] == 'default')
            CSLogger.info "Remote SG found, Reusing SG #{sg_group_id}"
            name = s[:name]
          elsif existing_sg
            name = s[:name]
            CSLogger.info "New SG #{name} created"
          end
        elsif ["Services::Network::SubnetGroup", "Services::Network::Generic::SubnetGroup::AWS"].include?(s[:type])
          uniq_id = ''
          s_group_provider_id =''
          s['properties'].each do |pro|
            uniq_id = pro['value'] if pro['name'] == 'uniq_provider_id'
            s_group_provider_id = pro['value'] if pro['name'] == 'provider_id'
          end
          if uniq_id.blank? && s_group_provider_id
            existing_sgroup = SubnetGroup.by_provider_id(params[:adapter_id], account.id, params[:region_id], s[:vpc_id], s_group_provider_id)
          elsif s_group_provider_id.blank? && uniq_id
            existing_sgroup = SubnetGroup.by_uniq_id(params[:adapter_id], account.id, params[:region_id], s[:vpc_id], uniq_id)
          elsif !s_group_provider_id.blank? && !uniq_id.blank?
            existing_sgroup = SubnetGroup.by_uniq_id(params[:adapter_id], account.id, params[:region_id], s[:vpc_id], s_group_provider_id)
          end
          if existing_sgroup
            name = s[:name]
            CSLogger.info "Existing #{name} reused"
          end
        elsif s[:type].include?("Services::Vpc")
          CSLogger.info "in VPC --- #{s.inspect}"
          vpc_provider_id = ''
          uniq_id = ''
          s['properties'].each do |pro|
            vpc_provider_id = pro['value'] if pro['name'] == 'vpc_id'
            uniq_id = pro['value'] if pro['name'] == 'uniq_provider_id'
          end
          if uniq_id.blank? && vpc_provider_id
            existing_vpc = Vpc.by_provider_id(params[:adapter_id], account.id, params[:region_id], vpc_provider_id)
          elsif vpc_provider_id.blank? && uniq_id
            existing_vpc = Vpc.by_uniq_id(params[:adapter_id], account.id, params[:region_id], uniq_id)
          end
          # existing_vpc = SecurityGroup.find_by(adapter_id: params[:adapter_id], account_id: account.id, region_id: params[:region_id], vpc_id: s[:vpc_id], name: s[:name])
          if existing_vpc
            name = s[:name]
            provider_id = vpc_provider_id
            uniq_provider_id = uniq_id
            CSLogger.info "VPC #{name} reused"              
          end
        end

        service_params = {
          geometry: s[:geometry],
          # account_id: account.id,
          name: name,
          additional_properties: s[:additional_properties],
          vpc_id: s[:vpc_id],
          region_id: params[:region_id],
          adapter_id: params[:adapter_id],
          created_at: s[:created_at].present? ? s[:created_at] : DateTime.now
        }
        # TODO: Generic Template
        # We do not need account_id in Generic template services
        service_params.merge!(account_id: account.id) unless template.generic_type?

        service = type.find_by(id: s[:id])

        if service.nil?
         status Status, :unauthorized, account.id, &block and return unless user.can_create?(Service, { account_id: account.id })

         CSLogger.error "couldn't find service, finding directory type"
          directory_service = Service.find_by(type: s[:type], state: :directory)
          service = directory_service.dup
          service.id = s[:id]
        end

        new_record = service.new_record?
        any_new_service_created = true if new_record
        service.assign_attributes(service_params.reject { |k,v| v.blank? })
        s[:properties].each do |property|
          next unless property[:value].present?
          service.send("#{property[:name]}=".to_sym, property[:value])
        end if s[:properties]
        service.service_tags =  s[:service_tags] if service.respond_to?(:service_tags) && s[:service_tags] && params["save_template_tags"]

        if s[:name_free_text]
          service.data_will_change!
          service.data['name_free_text'] = s[:name_free_text]
        end
        services_data[service.id] = {
          action: (new_record ? 'created' : 'edited'),
          properties: service.data,
          generic_type: service.generic_type,
          name: service.name
        }

        services_data[service.id].merge!({ changed_properties: get_changed_properties(service) }) unless new_record


        service.template! unless service.template?
        revision_data[:changed_services] << service.id if services_data[service.id][:changed_properties].present?

        # service_name = ServiceNamingDefault.get_name(service.account.security_group.first, provision_tags)

        # service_name = service.update_application_variables(service.name, user, nil, template)
        if uniq_provider_not_generated(service)
          service.data = service.data.merge('uniq_provider_id'=> Time.now.to_f.to_s.split(".").join)
          services_data[service.id].merge!(uniq_provider_id: service.data['uniq_provider_id'])
        end

        if service.generic_type.eql?("Services::Vpc")
          vpc = Vpc.where(state: "available", region_id: service.region_id, adapter_id: service.adapter_id, account_id: service.account_id, vpc_id: service.provider_id).first
          service[:vpc_id] = vpc.try(:id)
        end

        service.data_will_change!
        service.save!

        # services_data[service.id].merge!(uniq_provider_id: service.data['uniq_provider_id']) if service.is_sg? && !is_default?
        # if service.type == "Services::Compute::Server::AWS"
        #   service.assign_filers
        # end

        template.services << service if template.services.where(id: s[:id]).empty?
      end if params[:services]
      
      # Interfaces
      params[:services].each do |s|
        klass = ActionController::Base.helpers.sanitize(s[:type])
        type = klass.safe_constantize rescue ''
        # service = type.where(id: s[:id], account_id: params[:account_id]).first
        # TODO: Generic Template
        query = { id: s[:id] }
        query.merge!(account_id: account.id) unless template.generic_type?
        service = type.where(query).first
        next if service.blank?

        s[:interfaces].each do |i|
          interface_params = {
            name: i[:name],
            depends: i[:depends],
            interface_type: i[:interface_type],
            service: service
          }

          interface = service.interfaces.where(id: i[:id]).first_or_create

          # if interface.new_record?
          #   status Status, :unauthorized, interface.id, &block and return unless user.can_create?(Interface, { account_id: account.id })
          # else
          #   status Status, :unauthorized, interface.id, &block and return unless user.can_update?(interface)
          # end if !template.generic_type? # Should have check for generic template interfaces
          interface.update!(interface_params)
          interface.save!

        end unless s[:interfaces].nil? || s[:interfaces].empty?
      end if params[:services]
      # # Connections
      
      params[:services].each do |s|
        klass = ActionController::Base.helpers.sanitize(s[:type])
        type = klass.safe_constantize rescue ''
        # service = type.where(id: s[:id], account_id: params[:account_id]).first
        # TODO: Generic Template
        query = { id: s[:id] }
        query.merge!(account_id: account.id) unless template.generic_type?
        service = type.where(query).first
        next if service.blank?

        s[:interfaces].each do |i|

          if i[:depends]
            interface = service.interfaces.where(id: i[:id]).first

            i[:connections].each do |c|
              remote_interface = Interface.where(id: c[:remote_interface_id]).first
              relation = Connection.where(id: c[:id]).first_or_create
              relation.interface = interface
              relation.remote_interface = remote_interface

              # if relation.new_record?
              #   status Status, :unauthorized, relation.id, &block and return unless user.can_create?(Connection, { account_id: account.id })
              # else
              #   status Status, :unauthorized, relation.id, &block and return unless user.can_update?(relation)
              # end if !template.generic_type? # Should have check for generic template interfaces
              interface.connections << relation
            end if i[:connections]
          end
        end if s[:interfaces]
      end if params[:services]
      template.template_tags = params[:template_tags].nil? ? {} : params[:template_tags].each { |h| h.delete("id") } if params["save_template_tags"]
      template.selected_type = params[:selected_type].nil? ? 2 : params[:selected_type]

      template.updated_by = user.id
      template.updated_at = Time.now
      template.set_shared_with_attribute_of_template(user, params[:shared_with], params[:user_role_ids])
      if template.state == 'unhealthy'
        template.state = 'pending'
      end
      template.save
      template.save_defaults_names

      # Remove deleted objects
      if params[:revisions] && !params[:first_revision]
        service_ids = params[:revisions].to_h.inject([]) do |service_ids, (_, changed_service_hash)|
          next(service_ids) unless changed_service_hash.first
          service_ids << changed_service_hash.collect {|service_h| service_h['id']}
        end
        updated_services_data = services_data.select {|k,v| service_ids.flatten.include?(k)}
        revision_data[:services_data] = updated_services_data
      else
        updated_services_data = services_data
      end
      deleted_services = delete_services(params, template)
      delete_interfaces(params, template)
      if (options[:event] != :creation && (deleted_services.present? || any_new_service_created))
        template.increment_minor_revision!
        revision_data[:revision_changer] = true
      end

      unless template.generic_type?
        Behaviors::ReusableServicesUpdatable.set_reusable_service { template.services.vpcs }
        template_vpc = template.services.vpcs.first
        CSLogger.info "template_vpc---#{template_vpc.inspect}"
        update_vpc = Vpcs::AWS.find_by_vpc_id_or_uniq_provider_id(template_vpc.account_id, template_vpc.provider_id, template_vpc.uniq_provider_id).first
        # CSLogger.info "update_vpc----#{update_vpc.inspect}"
        if update_vpc && template.template_vpcs.present?
          template_vpcs_assoc = template.template_vpcs.first.update(vpc_id: update_vpc.id) 
        end
        template_vpc.additional_properties.merge!(primary_key: update_vpc.id) if update_vpc
        template_vpc.additional_properties_will_change!
        template_vpc.save
        template.services.update_all(vpc_id: update_vpc.id) if update_vpc
      end
      # CSLogger.info "VPC ----- ", Vpcs::AWS.where("data ->> 'uniq_provider_id' =?", template.services.vpcs.first.data['uniq_provider_id']).inspect
      template.services.subnet_groups.each do |service|
        if service.generic_type.eql?("Services::Network::SubnetGroup")
          service_subnet_ids = service.send(:parent_subnets_providers).collect(&:id).flatten
          service.data = service.data.merge('subnet_service_ids' => service_subnet_ids)
          service.data = service.data.merge('base_subnet_uuids' => get_base_subnet_uuids(service_subnet_ids))
          service.data = service.data.merge('subnet_ids' => get_base_subnet_provider_ids(service, service_subnet_ids))
          CSLogger.info "service.send(:parent_subnets_providers).collect(&:id).flatten:-- #{service.send(:parent_subnets_providers).collect(&:id).flatten}"
          service.data_will_change!
          service.save!
        end
      end

      template.services.where(type: "Services::Network::AvailabilityZone").each do |av|
        av.fetch_child_services("Services::Network::Subnet::AWS").each do |s|
          s.availability_zone = av.code
          s.save!
        end
      end

    # CSLogger.info "vpc_id ------ #{template.services.collect{|d| [d.type, d.vpc_id]}}"
      Behaviors::ReusableServicesUpdatable.set_reusable_service { template.services } unless template.generic_type?
      revision_data = update_revision_data(revision_data, updated_services_data, template, deleted_services)
      CSLogger.info "final revisiondata ======= ---- ---- #{revision_data.inspect}"
      event = if options[:event] == :creation
        Events::Template::Create.create(account: account, template: template, user: user, revision_data: revision_data)
      else
        if params[:revisions]
          Events::Template::Update.create(account: account, template: template, user: user, revision_data: revision_data)
        end
      end
    end
    template.reload
    # Added new key to identify that request is from from template
    # So we can prepare prepare Image same as build page, instead of auto-calculate algo


    params.merge!({:template => true})
    params.merge!({:provider => "AWS"})
    ImageService.save_image(params[:id], 'templates', user, params)
    template.notify_users(updator_name: user.name)
    status Status, :success, template, &block
    return template
  end


  def self.get_base_subnet_provider_ids(service, uuids)
    templated_subnet_services = Service.find(uuids)
    base_subnets = []
    templated_subnet_services.each do |subnet_service|
      attrs = {account_id: subnet_service.account_id, region_id: subnet_service.region_id, vpc_id: subnet_service.vpc_id, adapter_id: subnet_service.adapter_id, cidr_block: subnet_service.data['cidr_block']}
      base_subnets << Subnet.where(attrs).first
    end
    sg_group = SubnetGroups::AWS.where("data ->>'uniq_provider_id' = ?", service.data['uniq_provider_id']).first
    sg_group_older_subnet_ids = sg_group.subnet_ids.try(:compact) rescue []
    base_subnet_group_provider_ids =  base_subnets.collect(&:provider_id) rescue []
    (sg_group_older_subnet_ids + base_subnet_group_provider_ids).uniq.compact

  end

  def self.get_base_subnet_uuids(uuids)
    templated_subnet_services = Service.find(uuids)
    base_subnets = []
    templated_subnet_services.each do |subnet_service|
      attrs = {account_id: subnet_service.account_id, region_id: subnet_service.region_id, vpc_id: subnet_service.vpc_id, adapter_id: subnet_service.adapter_id, cidr_block: subnet_service.data['cidr_block']}
      base_subnets << Subnet.where(attrs).first
    end
    base_subnets.compact.collect(&:id) unless base_subnets.first.blank?
  end

  def self.uniq_provider_not_generated(service)
    if ["Services::Network::SecurityGroup", "Services::Network::SecurityGroup::AWS"].include? service.generic_type
      service.group_id.nil? && service.data['uniq_provider_id'].nil?
    elsif ["Services::Network::SubnetGroup", "Services::Network::SubnetGroup::AWS"].include? service.generic_type
      service.provider_id.nil? && service.data['uniq_provider_id'].nil?
    elsif ["Services::Vpc", "Services::Vpc::AWS"].include? service.generic_type
      service.provider_id.nil? && service.data['uniq_provider_id'].nil?
    end
  end

  def self.update_revision_data(revision_data, services_data, template, deleted_services)
    revision_data[:connections] = service_connection_map(services_data.keys)
    deleted_services.each { |service| services_data[service.id] = { action: 'deleted', generic_type: service.generic_type, properties: service.data_with_name, name: service.name } }
    deleted_services_ids = deleted_services.map(&:id)
    revision_data[:changed_services].push(*deleted_services_ids) if deleted_services_ids.present?
    revision_data[:number] = template.revision
    revision_data
  end

  def self.service_connection_map(service_ids)
    service_ids.inject({}) do |connection_map, service_id|
      connection_map[service_id] = {child_services: [], parent_services: [] }
      service = Service.where(id: service_id).first
      arr_of_child_services = service.arr_of_child_services unless service.blank?
      connection_map[service.id][:child_services] = arr_of_child_services if arr_of_child_services.present?
      unless service.blank?
        if service.parent_services.present?
          service.parent_services.each do |parent_class|
            remote_services = service.fetch_remote_services(parent_class.new.protocol)
            remote_services.each { |remote_service| connection_map[service.id][:parent_services] << remote_service.id } if remote_services.present?
          end
        end
      end
      connection_map
    end
  end

  def self.get_changed_properties(service)
    old_values_map, new_values_map = (service.data_was || {}), (service.data || {})
    new_values_map['name'] = service.name
    old_values_map['name'] = service.name_was

    new_values_map.inject([]) do |memo, (attr_name, new_value)|
      old_value = old_values_map[attr_name]
      attr_changed = (old_value.to_s != new_value.to_s)
      memo << attr_name if attr_changed
      memo
    end
  end

  def self.delete_interfaces(params, template)
    # connection_ids = params[:services].map { |s| s[:interfaces].map { |i| i.map { |intf| intf[:connections].map { |conn| conn[:id] } }  } unless s[:interfaces].nil? || s[:interfaces].empty? }
    connection_ids = params[:services].map { |s|
      s[:interfaces].map { |i|
        i[:connections].map { |conn|
          conn[:id]
        } unless i[:connections].nil? || i[:connections].empty?
    } unless s[:interfaces].nil? || s[:interfaces].empty? }
    connection_ids.flatten!

    template.services.each do |service|
      service.interfaces.each do |interface|
        interface.connections.where.not(id: connection_ids).destroy_all
      end
    end
  end

  def self.delete_services(params, template)
    # service_ids = params[:revisions] && params[:revisions]['delete'] ? params[:revisions]['delete'].collect {|deleted_service| deleted_service['id']} :
    # #params[:services].map { |x| x[:id] }
    # CSLogger.info service_ids.inspect
    if params[:revisions] && params[:revisions]['delete']
      service_ids = params[:revisions]['delete'].collect {|deleted_service| deleted_service['id']}
      services = template.services.where(id: service_ids)
    else
      service_ids = params[:services].map { |x| x[:id] }
      services = template.services.where.not(id: service_ids)
    end

    services.each do |service|
      service.interfaces.each do |interface|
        interface.connections.each { |connection| connection.destroy }
        Connection.where(remote_interface_id: interface.id).each { |c| c.destroy }
      end
    end
    services.each do |service|
      service.interfaces.destroy_all
    end
    services.each do |service|
      template.services.delete(service)
      service.template_service.destroy if service.template_service.present?
      TemplateService.where(service_id: service.id).destroy_all
      service.destroy
    end

    services
  end

  # updates template attributes
  def self.update_template_details(template, params, user, &block)
    begin
      template.update!(params.merge!("updated_by" => user.id))
      status Status, :success, template, &block
    rescue Exception => e
      status Status, :error, "Error in updating template", &block
    ensure
      return template
    end
  end
end
