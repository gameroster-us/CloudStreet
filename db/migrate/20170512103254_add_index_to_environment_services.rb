class AddIndexToEnvironmentServices < ActiveRecord::Migration[5.1]
  def change
  	add_index(:environment_services, [:environment_id, :service_id])
  	add_index(:environment_services, [:service_id, :environment_id])
  end
end
