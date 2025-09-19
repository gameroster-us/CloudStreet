class AddFieldsToMachineImage < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :block_device_mapping, :text
    add_column :machine_images, :image_owner_alias, :string
    add_column :machine_images, :image_owner_id, :string
    add_column :machine_images, :product_codes, :text
    add_index  :machine_images, :image_id, :unique => true
  end
end
