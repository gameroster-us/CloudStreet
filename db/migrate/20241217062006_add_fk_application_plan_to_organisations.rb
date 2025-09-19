class AddFkApplicationPlanToOrganisations < ActiveRecord::Migration[5.2]
  def change
   add_foreign_key :organisations, :application_plans, column: :application_plan_id, on_update: :restrict, on_delete: :restrict, name: 'fk_application_plan'
  end
end
