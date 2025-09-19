class UserActivityWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false

  def perform
    begin
      CSLogger.info "Started updating user activity in background"
      user_activities = UserActivity.all
      user_activities.each do |user_activity|
        progress = user_activity.progress
        next if progress.blank?
        success_calculation = progress["total"] == 0 ? 0 :((progress["success"].to_f/progress["total"].to_f)*100).round(2)
        failed_calculation = progress["total"] == 0 ? 0 :((progress["failure"].to_f/progress["total"].to_f)*100).round(2)
        progress.merge!({"success_percentage" => success_calculation, "failed_percentage" => failed_calculation})
        progress.delete("percentage")
        CSLogger.info "------#{progress}------------------"
        user_activity.update(:progress => progress)
      end
      CSLogger.info "Completed updating user activity in background"
    rescue Exception => e
      CSLogger.error "#{e.message} ---#{e.backtrace}"
    end
  end
end