class UpdateIndexMachineImageGroup < ActiveRecord::Migration[5.1]
  def change
  	remove_index :machine_image_groups, [:match_key, :region_id]
  	add_index :machine_image_groups, [:match_key, :region_id]
  end
end
