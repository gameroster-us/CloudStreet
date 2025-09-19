class AddOwnerIdIndexToMachineImage < ActiveRecord::Migration[5.1]
  def change
  	add_index :machine_images, :image_owner_id
  end
end
