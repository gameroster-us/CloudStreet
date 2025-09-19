class AddDiskTypeToAzureDisks < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_disks, :disk_type, :string
  end
end
