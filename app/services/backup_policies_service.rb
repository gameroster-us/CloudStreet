class BackupPoliciesService < CloudStreetService
  extend TaskService::OptOut::Helper

  def self.search(user, organisation, page_params, policy_params, &block)
    user = fetch User, user
    policies = organisation.account.backup_policies.list_compact.order(created_at: :desc)
    policies = policies.where('name LIKE ? ', "%#{policy_params[:name]}%") if policy_params[:name].present? # filtered the policies as per parameter search from name
    policies, total_records = apply_pagination(policies, page_params, false)
    status Status, :success, { total_records: total_records, policies: policies }, &block
  end

  def self.find(organisation, options, &block)
    policy = organisation.account.backup_policies.find_by(id: options[:id])
    if policy.present?
      status Status, :success, policy, &block
    else
      CSLogger.error('Policy not present')
      CSLogger.error policy.inspect
      CSLogger.error policy.try(:errors)
      status Status, :error, policy, &block
    end
  rescue StandardError => e
    CSLogger.error "Error in find policy = #{e.message}"
    CSLogger.error e.backtrace
    status Status, :error, nil, &block
  end

  def self.create(user, organisation, policy_params, &block)
    user = fetch User, user
    policy = organisation.account.backup_policies.build(policy_params)
    policy.creator = policy.updator = user
    if policy.valid?
      if policy.save
        status Status, :success, policy.get_compact, &block
      else
        status Status, :error, nil, &block
      end
    else
      status Status, :validation_error, policy, &block
    end
  end

  def self.update(user, organisation, policy_params, &block)
    user = fetch User, user
    policy = organisation.account.backup_policies.where(id: policy_params[:id]).first
    unless policy.present?
      status Status, :not_found, nil, &block
      return
    end
    policy.attributes = policy_params
    policy.adapter_id = nil unless policy_params['is_bunker_option']
    policy.retention_period = nil unless policy_params['is_backup_retention']
    if policy.valid?
      if policy.save
        status Status, :success, policy.get_compact, &block
      else
        status Status, :error, nil, &block
      end
    else
      status Status, :validation_error, policy, &block
    end
  end

  def self.destroy(user, organisation, policy_id, &block)
    user = fetch User, user
    policy = organisation.account.backup_policies.where(id: policy_id).list_compact.first
    if policy.present? && policy.backup_policy_engaged?
      event_list = get_events_involving_policy(policy_id)
      status Status, :unauthorized, "Policy can not be deleted as it has been used by #{event_list}", &block
    elsif policy.nil? || policy.destroy
      status Status, :success, policy, &block
    else
      status Status, :error, nil, &block
    end
  end

  def self.show(policy_id, &block)
    policy = BackupPolicy.find(policy_id)
    if policy
      status Status, :success, policy, &block
    else
      status Status, :error, nil, &block
    end
  end

  def self.execute_policies(task, activity_id, batch_id)
    user = task.creator
    policy_id = task.backup_policy_id
    region_ids = task.region_ids
    account = task.account
    adapter_ids = task.permitted_adapter_ids
    policy = account.backup_policies.where(id: policy_id).first
    if policy
      if task.environment_ids.present?
        Task.unauthorized_adapters_logging(task, "env", {action_name: "backup", user_activity_id: activity_id})
        task.environment_ids.each do|env_id|
          environment = account.environments.adapter_id(task.task_tenant_adapter_ids).find_by_id(env_id)
          next unless environment.present?
          services = environment.services
          snapshots = environment.all_snapshots.to_a
          services = filter_backupable_service(services, policy)
          call_backup_service(services.to_a + snapshots, policy, user, task,activity_id, batch_id)
        end
      elsif (task.event_for.present? && task.event_for.include?('environment'))
        Task.unauthorized_adapters_logging(task, 'env', {action_name: 'backup', user_activity_id: activity_id})
        tag_keys = task.environment_tags.map { |h| h['tag_key'] }.uniq
        tag_value = task.environment_tags.map { |h| h['tag_value'] }.uniq
        general_setting = GeneralSetting.find_by(account_id: account)
        if general_setting&.is_tag_case_insensitive
          environment_tag_keys = tag_keys.map(&:downcase)
          environment_tag_values = tag_value.map(&:downcase)
          environments = Environment.exclude_environment.joins(:environment_tags).where(:default_adapter_id => task_tenant_adapter_ids, region_id: region_ids).where('LOWER(environment_tags.tag_key) IN (?) and LOWER(environment_tags.tag_value) IN (?)',environment_tag_keys,environment_tag_values).pluck(:environment_id).uniq
        else
          environments = Environment.exclude_environment.joins(:environment_tags).where(:default_adapter_id => task_tenant_adapter_ids, region_id: region_ids).where('environment_tags.tag_key IN (?) and environment_tags.tag_value IN (?)',tag_keys,tag_value).pluck(:environment_id).uniq
        end
        return unless environments.present?

        environments.each do |env|
          environment = Environment.find(env)
          services = environment.services
          snapshots = environment.all_snapshots.to_a
          services = filter_backupable_service(services, policy)
          call_backup_service(services.to_a + snapshots, policy, user, task, activity_id, batch_id)
        end
      elsif (task.event_for.present? && task.event_for.include?('service'))
        Task.unauthorized_adapters_logging(task, "service", {action_name: "backup", user_activity_id: activity_id})
        task.environment_tags.map{|s| s['tag_value'] = nil if s['tag_value'].eql? ''}
        services = task.services
        snapshots = task.snapshots
        services = filter_backupable_service(services, policy)
        all_services = services + snapshots + task.services(true) + task.snapshots(true) # Services with Opt-Out count
        task.set_progress_data('total', all_services.count) # Set progress data including Opt-Out services
        call_backup_service(services.to_a + snapshots.to_a, policy, user, task, activity_id, batch_id)
      end
    end
  end

  def self.backup_service(service, policy, user, task, activity_id)
    service.user = user
    ESLog.info "=======#{service.id}=====#{service.provider_id}==========="
    service.exec_backup(policy, task, activity_id)
  end

  def self.call_backup_service(services, policy, user, task, activity_id, batch_id)
    if services.count >= 1
      parent_batch = Sidekiq::Batch.new(batch_id)
      parent_batch.jobs do
        event_batch = Sidekiq::Batch.new
        event_batch.description = 'Backup Event Execution To Task Worker'
        options = { task_id: task.id }
        event_batch.on(:complete, Tasks::AWS::EventExecutionCallback::BackupEventExecutionCallback, options)
        event_batch.on(:success, Tasks::AWS::EventExecutionCallback::BackupEventExecutionCallback, options)
        event_batch.jobs do
          services.each_slice(20) do |backup_services|
            backup_services.each do |service|
              if service.can_be_backed_up?(policy)
                backup_service(service, policy, user, task, activity_id)
                sleep(1)
              end
            end
            sleep(5)
          end
        end
        event_batch.jobs do
          data = { action_name: 'backup', user_activity_id: activity_id, resource_destination_adapter_name: policy.adapter.present? ? policy.adapter.try(:name) : nil }
          prepared_data_for_opt_out_services(task, activity_id, data) # Call fot Opt-Out Service logger
        end
      end
    elsif task.services(true).count >= 1 || task.snapshots(true).count >= 1
      data = { action_name: 'backup', user_activity_id: activity_id, resource_destination_adapter_name: policy.adapter.present? ? policy.adapter.try(:name) : nil }
      prepared_data_for_opt_out_services(task, activity_id, data)
    end
  end

  def self.filter_backupable_service(services, policy)
    return [] if policy.blank?
    return [] if services.blank?
    services = services.where.not(state: Service::SERVICE_DELETING_STATES)
    # for getting volumes and server
    services_arr = if (policy.will_backup_root_volumes? || policy.will_backup_non_root_volumes?) && policy.will_backup_servers?
                     servers = services.instance_servers
                     server_attached_volume_ids = servers.each_with_object([]) { |server, memo| memo.concat(server.server_attached_volumes.map { |h| h['provider_id'] }) }.uniq
                     volumes = services.volumes.where.not(provider_id: server_attached_volume_ids)
                     servers.to_a + volumes.uniq(&:provider_id)
                   # for getting only volumes
                   elsif (policy.will_backup_root_volumes? || policy.will_backup_non_root_volumes?) && !policy.will_backup_servers?
                     services.volumes.uniq(&:provider_id)
                   # for getting only servers
                   elsif !(policy.will_backup_root_volumes? || policy.will_backup_non_root_volumes?) && policy.will_backup_servers?
                     services.instance_servers.to_a
                   end
    # for getting rds services
    services_arr = (services_arr || []) + services.databases.to_a if policy.will_backup_databases?
    return services_arr
  end

  def self.get_events_involving_policy(policy_id)
    tasks = Task.where(backup_policy_id: policy_id).order('created_at DESC').pluck(:title)
    "#{'event'.pluralize(tasks.count)} : #{tasks.join(', ')}"
  end
end
