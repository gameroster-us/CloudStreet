# frozen_string_literal: true

# Helper methods for deleting Task
module TaskService::ModelHelpers::Delete
  # Class methods
  module ClassMethods
    TASK_WORKERS = %w[TaskWorker EventNotificationWorker AWSOptOutEventNotificationWorker AzureOptOutEventNotificationWorker DryRunEventNotificationWorker EnvironmentStartTaskWorker EnvironmentStopTaskWorker].freeze

    def delete_event_jobs(task_ids)
      ss = Sidekiq::ScheduledSet.new
      ss.each do |job|
        job.delete if TASK_WORKERS.include?(job.klass) && (task_ids.include?(job.args[0]) || task_ids.include?(job.args[0]['task_id']))
      end
    end
  end

  # Instance methods
  module InstanceMethods
    def can_delete?(end_datetime)
      end_datetime > Time.now.utc
    end

    def delete_data(params)
      end_datetime = params[:end_datetime].present? ? Time.parse(params[:end_datetime]) : Time.now.utc + 1.minute
      cleared_task_ids = [id]
      if !repeat?
        if last_execuation_time.nil?
          destroy
        else
          data.merge!(start_stop_next_execuation_time: nil) if task_type == 'env_start_stop'
          update_columns(next_execuation_time: nil, data: data)
        end
      else
        self.end_schedule = if schedule_type == 'hourly' || schedule_type == 'minutely'
                              { ends: true, end_datetime: (end_datetime - 30.seconds).utc.to_s }
                            else
                              { ends: true, end_datetime: (end_datetime - 1.day + 1.hour).utc.to_s }
                            end
        end_schedule_will_change!
        if last_execuation_time.nil? && schedule.previous_occurrence(end_datetime).blank?
          destroy
          last_active_task = Task.where('id = ? OR parent_id = ?', (parent_id || id), (parent_id || id)).where('start_datetime < ?', end_datetime).order('start_datetime desc').first
        else
          last_active_task = self
        end
        if last_active_task
          # last_active_task.schedule.recurrence_rules.first.until(end_datetime-1.day+1.hour)
          # last_active_task.schedule.recurrence_rules.first.count(nil)
          delete_datetime = if schedule_type == 'hourly' || schedule_type == 'minutely'
                              params[:end_datetime].present? ? Time.parse(params[:end_datetime]) - 30.seconds : Time.now.utc + 1.minute
                            else
                              params[:end_datetime].present? ? Time.parse(params[:end_datetime]) - 1.day + 1.hour : Time.now.utc + 1.minute
                            end
          count = last_active_task.schedule.occurrences_between(last_active_task.start_datetime, delete_datetime).count
          last_active_task.schedule.recurrence_rules.first.count(count)
          update_columns(schedule: schedule)
          update_columns(next_execuation_time: nil) unless schedule.remaining_occurrences.present?
          data.merge!(start_stop_next_execuation_time: nil)
          update_columns(data: data) if task_type == 'env_start_stop'
          Task.where('id = ? OR parent_id = ?', (parent_id || id), (parent_id || id)).update_all(end_schedule: end_schedule)
        end
        cleared_task_ids += delete_future_tasks!(end_datetime)
      end
      Task.delete_event_jobs(cleared_task_ids)
      cleared_task_ids
    end

    def delete_future_tasks!(end_datetime)
      cleared_task_ids = Task.where('id = ? OR parent_id = ?', (parent_id || id), (parent_id || id)).pluck(:id)
      deleted_task_ids = Task.where(parent_id: (parent_id || id)).where('start_datetime > ?', end_datetime).pluck(:id)
      unless deleted_task_ids.empty?
        ActiveRecord::Base.connection.execute("delete from environments_tasks where task_id IN ('#{deleted_task_ids.join("','")}')")
        ActiveRecord::Base.connection.execute("delete from adapters_tasks where task_id IN ('#{deleted_task_ids.join("','")}')")
        Task.where(id: deleted_task_ids).delete_all
      end
      cleared_task_ids
    end

    # Code to Reschedule Task
    def reschedule_jobs(_cleared_task_ids)
      Task.select(:id, :schedule)
          .where('id = ? OR parent_id = ?', (parent_id || id), (parent_id || id))
          .each do |task|
        schedule_time = task.schedule.remaining_occurrences.first
        event_batch = Sidekiq::Batch.new
        event_batch.description = 'Event Batch'
        options = { task_id: task.id }
        event_batch.on(:complete, EventBatchCallback::EventCallback, options)
        event_batch.on(:success, EventBatchCallback::EventCallback, options)
        event_batch.jobs do
          TaskWorker.perform_at(schedule_time, task.id) if schedule_time
        end
      end
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
