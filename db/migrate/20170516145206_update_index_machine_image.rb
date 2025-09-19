class UpdateIndexMachineImage < ActiveRecord::Migration[5.1]
  def change
  	add_index :machine_images, :image_id
  end
end
