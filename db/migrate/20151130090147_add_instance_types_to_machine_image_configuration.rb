class AddInstanceTypesToMachineImageConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_image_configurations, :instance_types, :string, array: true, default: [], null: false
  end
end
