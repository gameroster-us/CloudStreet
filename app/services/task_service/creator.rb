# frozen_string_literal: true

# Task Creator
class TaskService::Creator < CloudStreetService
  include TaskService::ServiceHelpers::Notification
  class << self
    ## Code to create task services
    def create(current_user, current_account, params, current_tenant, &block)
      task_params = params.dup
      task_params[:created_by] = current_user.id
      task_params[:account_id] = current_account.id
      task = "Task::#{params[:provider]}".constantize.init_from(current_user, task_params, current_tenant)
      task.status ||= 'pending'
      save_status = task.save
      #skipping unique account verification on task create
      adapter_validation = task.errors.messages.all? do |attribute, messages|
        (attribute == :adapters && messages == ["is invalid"]) ||
        (attribute == :adapter_groups && messages == ["is invalid"])
      end
      if adapter_validation ? task.save(validate: false) : save_status
        ESLog.info "===TASK=AFTER=SAVE====#{task.title}==============="
        schedule_time = task.schedule.first
        task.update_columns(next_execuation_time: schedule_time) if schedule_time
        event_batch = Sidekiq::Batch.new
        event_batch.description = 'Event Batch'
        options = { task_id: task.id }
        event_batch.on(:complete, EventBatchCallback::EventCallback, options)
        event_batch.on(:success, EventBatchCallback::EventCallback, options)
        event_batch.jobs do
          TaskWorker.perform_at(schedule_time, task.id) if schedule_time
        end
        new_task = Task.with_policy_names.where(id: task).first
        # FollowUpEmail.check_and_inactive_followup_if_any(current_user.id, current_account.id, 'NO-SCHEDULED-SYNC') if task.task_type == 'sync'
        status Status, :success, new_task, &block
      else
        status Status, :validation_error, task.errors.messages, &block
      end
    end
  end
end
