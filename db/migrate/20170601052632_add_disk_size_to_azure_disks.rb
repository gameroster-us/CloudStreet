class AddDiskSizeToAzureDisks < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_disks, :disk_size, :float
  end
end
