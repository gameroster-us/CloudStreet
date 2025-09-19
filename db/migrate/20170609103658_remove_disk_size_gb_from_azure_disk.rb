class RemoveDiskSizeGbFromAzureDisk < ActiveRecord::Migration[5.1]
  def change
    remove_column :azure_disks, :disk_size_gb, :integer
    remove_column :azure_virtual_machines, :vhd, :json
    add_column :azure_disks, :vhd_uri, :text
    add_column :azure_disks, :caching, :string
    add_column :azure_disks, :lun, :string
  end
end
