class AddAmiConfigCategoryIdToMachineImageConfiguration < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_image_configurations, :ami_config_category_id, :uuid
    add_index  :machine_image_configurations, :ami_config_category_id
  end
end
