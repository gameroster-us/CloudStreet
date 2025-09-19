class AddCreationDateToMachineImages < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :creation_date, :timestamp
  end
end
