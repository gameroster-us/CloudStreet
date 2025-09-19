class AddApplicationIdToEnvironment < ActiveRecord::Migration[5.1]
	def change
    add_column :environments, :application_id, :uuid
  end
end