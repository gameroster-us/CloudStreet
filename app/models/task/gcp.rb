class Task::GCP < Task
  after_commit :reset_task_environments, if: proc { (env_start? || env_stop? || env_terminate? || env_start_stop? || backup_services? || env_ec2_right_size? || recommendation_policy_action?) }, on: %i(create update)

  def reset_task_environments(notification_flag = true)
    ESLog.info '-------SET LINK SERVICE WITH TASK-------------'
    update_columns(data_prepared: false) # Set to false beacuse data prepared in bg after completed set to true
    event_batch = Sidekiq::Batch.new
    event_batch.description = 'Link Task With Service'
    options = { task_id: id, send_notification_required: notification_flag }
    event_batch.on(:complete, EventBatchCallback::TaskServiceLinkCallback, options)
    event_batch.on(:success, EventBatchCallback::TaskServiceLinkCallback, options)
    event_batch.jobs do

      GCPLinkServicesToTaskWorker.perform_async(id)
    end
  end

  def get_resources_for_task(batch_id = nil)
    ESLog.info "-----------------------------------Updating service_ids for task #{title}---------------"
    applicable_adapter_ids = adapter_group_ids.present? ? ServiceGroup.adapterids_from_adapter_group(adapter_group_ids) : adapter_ids
    filters = { account_id: account_id, region_id: region_ids, adapter_id: applicable_adapter_ids }
    # TODO: hook to update environment tasks table
    return unless environment_tags.present?
    return unless event_for.present?
    task_applicable_recommendation_services(filters, batch_id = nil) if event_for.include?('recommendation_service') && recommendation_policy_action?
    # task_applicable_services(filters, batch_id) if event_for.include?('service')
  end

  def task_applicable_recommendation_services(filters, batch_id = nil)
    ESLog.info "====in==task_applicable_services=========#{title}=============="
    task_details.destroy_all if task_details.present?

    policy = RecommendationPolicy.find(recommendation_policy_id)
    tenant_tasks_records = adapter_groups_tasks.where(task_id: tenant.tasks.ids)
    tenant_tasks_records.without_adapter_group_ids(adapter_group_ids).update_all(tenant_access: false)
    tenant_tasks_records.with_adapter_group_ids(adapter_group_ids).update_all(tenant_access: true)
    adapter_group_ids = permitted_adapter_group_ids
    adapter_ids_from_groups = ServiceGroup.adapterids_from_adapter_group(adapter_group_ids)
    adapter_ids = adapter_ids_from_groups.present? ? adapter_ids_from_groups : permitted_adapter_ids
    region_ids = policy.account.get_enabled_regions('GCP').pluck(:id) & (filters[:region_id] || [])

    options = {
      tags: (environment_tags || []),
      tag_operator: tag_operator || 'OR',
      is_exclude_spot_instances: is_exclude_spot_instances || false,
      only_count: false
    }
    CurrentAccount.account = account
    services = policy.unused_services(adapter_ids, region_ids, options)
    TaskDetails::GCP.bulk_import(self, services)
  end

  def services(is_opt_out = false)
    return [] unless task_details.filter_by_opt_out(is_opt_out).present? # Filtered the services based on the opt out

    provider_id = task_details.filter_by_opt_out(is_opt_out).pluck(:resource_identifier).uniq 
    permitted_adapters_ids = permitted_adapter_group_ids.present? ? ServiceGroup.adapterids_from_adapter_group(permitted_adapter_group_ids) : permitted_adapter_ids
    # exclude deleting state services later
    services = ::GCP::Resource.where(provider_id: provider_id, adapter_id: permitted_adapters_ids, region_id: region_ids)

    if %w[idle_running idle_stopped].include? additional_conditions
      services = services.where(state: 'running') if additional_conditions.eql? 'idle_running'
      services = services.where(state: 'stopped') if additional_conditions.eql? 'idle_stopped'
      # self.task_details.where.not(resource_identifier: services.pluck(:provider_id)).delete_all
    end
    services
  end

  def snapshots(is_opt_out = false)
    []
  end

end
