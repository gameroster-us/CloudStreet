class AddNameToMachineImages < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :name, :string
  end
end
