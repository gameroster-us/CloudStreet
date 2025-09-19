class RemoveIndexMachineImagesOnImageId < ActiveRecord::Migration[5.1]
  def change
  	remove_index :machine_images, :image_id
  end
end
