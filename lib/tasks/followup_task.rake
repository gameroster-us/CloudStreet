namespace :followup_task do
  task start: :environment do
  	FollowUpEmailService.find_and_schedule_followups
  	FollowUpEmailService.process_scheduled_followups
  end
end