class CreateAdaptersMachineImages < ActiveRecord::Migration[5.1]
  def change
    create_table :adapters_machine_images, :id => false do |t|
	    t.uuid :adapter_id, index: true
	    t.uuid :machine_image_id, index: true
    end
  end
end
