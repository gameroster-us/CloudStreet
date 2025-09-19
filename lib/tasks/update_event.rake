namespace :update_event do
  desc "Update event for job type"
  task job_type: :environment do
    begin
      Task.all.each do |task|
        if task.schedule.recurrence_rules.present?
          task.schedule_type = task.schedule.recurrence_rules.first.class.to_s.split('::').last.underscore.split('_').first
          task.last_execuation_time = task.schedule.previous_occurrence(Time.now)
          task.next_execuation_time = task.schedule.next_occurrence(Time.now)
          task.status = 'success'
          task.save
        end
      end
    rescue StandardError => e
      CSLogger.error("#{e.class} #{e.message} #{e.backtrace}")
    end
  end
end