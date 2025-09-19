class AddDefaultsToMachineImageConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_image_configurations, :account_id, :uuid, index: true
    add_column :machine_image_configurations, :is_template, :boolean, :default => false
    add_index :machine_image_configurations, :account_id
  end
end
