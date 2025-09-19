class UpdateApplicationPlanTo30DaysTrialPeriod < ActiveRecord::Migration[5.1]
  def up
    application_plan = ApplicationPlan.find_by(name: 'normal')
    application_plan.update(trial_period_days: 30) if application_plan.present?
  end

  def down
    application_plan = ApplicationPlan.find_by(name: 'normal')
    application_plan.update(trial_period_days: 0) if application_plan.present?
  end
end
