class AddTrialPeriodDaysToOrganisation < ActiveRecord::Migration[5.1]
	def change
		add_column :organisations, :trial_period_days, :integer
	end
end
