class LoadBalancers::Updator < CloudStreetService

  include Behaviors::ReusableServicesUpdatable

  def self.register_instances(load_balancer, organisation, instance_ids, user, &block)
    registerable_instances = load_balancer.environment.services.instance_servers.where(id: instance_ids)
    if(registerable_instances.count != instance_ids.count)
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.server_out_of_scope')], &block  
    else
      registered_instances = load_balancer.environment.services.instance_servers.select{|instance|
        interface = instance.interfaces.where({ interface_type: 'Protocols::LoadBalancer'}).first
        interface && interface.remote_interfaces.where(service_id: load_balancer.id).present? 
      }
      instances_to_be_detached = registered_instances.reject{|instance| instance_ids.include?(instance.id)}
      load_balancer.deregister_instances(instances_to_be_detached) unless instances_to_be_detached.empty?
      load_balancer.register_instances(registerable_instances) unless registerable_instances.empty?
      revision_data = load_balancer.environment.prepare_revision_data(event: 'updated', service: load_balancer.reload)
      Events::Service::Update.create(account: organisation.account, service: load_balancer.reload, environment: load_balancer.environment, user: user, revision_data: revision_data)
      status ServiceStatus, :success, load_balancer, &block
    end
  end

  def self.apply_security_groups(load_balancer, organisation, security_group_ids, user, &block)
    if security_group_ids.empty?
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.min_security_groups_required_to_be_attached')], &block
      return
    end
    security_groups_to_attach = SecurityGroups::AWS.where(id: security_group_ids)
    load_balancer.user = user
    Behaviors::ReusableServicesUpdatable.create_remote_services_from_pending(security_group_ids, "SecurityGroups::AWS", "Services::Network::SecurityGroup::AWS", load_balancer)
    if(security_groups_to_attach.count != security_group_ids.count)
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.security_group_out_of_scope')], &block  
    else
      load_balancer.apply_security_groups(security_groups_to_attach)
      revision_data = load_balancer.environment.prepare_revision_data(event: 'updated', service: load_balancer.reload)
      Events::Service::Update.create(account: organisation.account, service: load_balancer.reload, environment: load_balancer.environment, user: user, revision_data: revision_data)
      status ServiceStatus, :success, load_balancer, &block
    end  
  end

  def self.attach_subnets(load_balancer, organisation, subnet_ids_to_be_attached, user, &block)
    if subnet_ids_to_be_attached.empty?
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.min_subnets_required_to_be_attached')], &block
      return
    end
    attached_subnets = load_balancer.interfaces.where(:interface_type=>'Protocols::Subnet').first.remote_interfaces.collect{|ri| ri.service}
    subnets_to_be_attached = load_balancer.environment.services.subnets.where(id: subnet_ids_to_be_attached)
    available_subnet_ids = load_balancer.environment.services.subnets.pluck(:id)

    if((available_subnet_ids & subnet_ids_to_be_attached).sort != subnet_ids_to_be_attached.sort)
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.subnets_out_of_scope')], &block  

    elsif subnets_to_be_attached.group_by{|subnet| subnet.fetch_availability_zone_name }.values.map(&:length).any?{|count| count > 1 }
      status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.one_subnet_per_az_can_be_attached')], &block

    else
      unless(attached_subnets.map(&:id).sort == subnet_ids_to_be_attached.sort)
        common_subnets = attached_subnets.map(&:id).sort & subnet_ids_to_be_attached.sort
        subnets_to_be_detached = attached_subnets.reject{|subnet| subnet_ids_to_be_attached.include?(subnet.id)}
        load_balancer.detach_subnets(subnets_to_be_detached) unless subnets_to_be_detached.empty? || common_subnets.empty?
        attach_exception_check = load_balancer.attach_subnets(subnets_to_be_attached)
        if attach_exception_check.present?
          load_balancer.detach_subnets(subnets_to_be_detached) unless subnets_to_be_detached.empty? || common_subnets.present?
        end
      end
      if attach_exception_check.blank?
        status ServiceStatus, :validation_error, [I18n.t('validator.error_msgs.services.lb.same_az_subnet')], &block
      else
        revision_data = load_balancer.environment.prepare_revision_data(event: 'updated', service: load_balancer.reload)
        Events::Service::Update.create(account: organisation.account, service: load_balancer.reload, environment: load_balancer.environment, user: user, revision_data: revision_data)
        status ServiceStatus, :success, load_balancer, &block
      end
    end
  end

end
