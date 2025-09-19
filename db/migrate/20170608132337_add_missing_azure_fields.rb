class AddMissingAzureFields < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_disks, :disk_size_gb, :integer
    add_column :azure_disks, :account_type, :string
    add_column :azure_disks, :os_type, :string
    remove_column :azure_disks, :vhd_uri, :string
    remove_column :azure_disks, :caching, :string
    remove_column :azure_disks, :disk_type, :string
    remove_column :azure_virtual_machines, :vm_id, :string
    add_column :azure_virtual_machines, :vhd, :json
    remove_column :azure_network_interfaces, :network_security_group_id, :string if column_exists? :azure_network_interfaces, :network_security_group_id
  end
end
