class ChangeIndexesOnMachineImages < ActiveRecord::Migration[5.1]
  def change
    remove_index :machine_image_groups, :column => [:name]
    add_index :machine_image_groups, [:name, :region_id], :unique => true
    remove_column :machine_images, :group_key
    remove_column :machine_images, :group_match
  end
end
