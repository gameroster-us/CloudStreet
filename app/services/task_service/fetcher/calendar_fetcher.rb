# frozen_string_literal: true

# Class to fetch data for Calender
class TaskService::Fetcher::CalendarFetcher < CloudStreetService
  class << self
    ## Code to fetch tasks for calender view
    def get_all(current_account, current_tenant, filters, &block)
      tasks = []
      account_tasks = Task.get_tenant_wise_tasks(current_account.tasks, current_tenant, current_account)
      if filters[:start_datetime] && filters[:end_datetime]
        tasks += account_tasks.with_policy_names.non_recurring_tasks(filters)
        tasks += account_tasks.with_policy_names.recurring_tasks(filters).to_a
      end
      tasks = account_tasks.environment_future_tasks(filters[:environment_id]) if filters[:environment_id]
      tasks_list = add_task_accessibility(tasks, current_tenant)
      status Status, :success, tasks_list, &block
    end

    # Add accessibility parameter to true if the task was under the current tenant
    def add_task_accessibility(tasks, current_tenant)
      tasks.inject([]) do |list, task|
        task.task_accessibility = task.tenant_id.eql?(current_tenant.id) ? true : false
        list << task
      end
    end
  end
end
