class AddApplicationPlanIdToOrganisations < ActiveRecord::Migration[5.1]
  def change
			add_column :organisations, :application_plan_id, :uuid
	end	
end
