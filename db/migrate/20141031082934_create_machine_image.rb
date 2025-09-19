class CreateMachineImage < ActiveRecord::Migration[5.1]
  def change
    create_table :machine_images , id: :uuid  do |t|
      t.uuid    :adapter_id, index: true
      t.uuid    :region_id, index: true
      t.string :architecture
      t.string :description
      t.string :image_id
      t.string :image_location
      t.string :image_state
      t.string :image_type
      t.string :is_public
      t.string :kernel_id
      t.string :platform
      t.string :ramdisk_id
      t.string :root_device_name
      t.string :root_device_type
      t.string :virtualization_type

      t.timestamps
    end
  end
end
