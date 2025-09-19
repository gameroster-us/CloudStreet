class AddServicetagToMachineImage < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :service_tags, :json
  end
end
