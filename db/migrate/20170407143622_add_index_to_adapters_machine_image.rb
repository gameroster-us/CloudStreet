class AddIndexToAdaptersMachineImage < ActiveRecord::Migration[5.1]
  def change
  	add_index :adapters_machine_images, :adapter_id
  	add_index :adapters_machine_images, [:adapter_id, :machine_image_id], :name => 'adapter_machine_images_grouped_colume_index'
  	add_index :adapters_machine_images, :machine_image_id
  end
end
