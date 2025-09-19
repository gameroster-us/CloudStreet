class AddGroupKeyToMachineImages < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :group_key, :string
    add_column :machine_images, :group_match, :string
  end
end
