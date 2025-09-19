# frozen_string_literal: true

# Worker to update tanant's adapter access for existing task
class Tasks::AdaptersTenantAccessForTasksWorker
  include Sidekiq::Worker
  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(tenant_id, selected_adapter_ids)
    tenant = Tenant.find_by(id: tenant_id)
    return unless tenant.present?

    tenant_tasks_records = AdaptersTask.where(task_id: tenant.tasks.ids)
    return unless tenant_tasks_records.present?

    ESLog.info "======Updating Adapter's access fot tenant #{tenant.name}======="
    tenant_tasks_records.without_adapter_ids(selected_adapter_ids).update_all(tenant_access: false)
    tenant_tasks_records.adapter_ids(selected_adapter_ids).update_all(tenant_access: true)
  rescue StandardError => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end
end
