class AddMissingColumnsInAzureTables < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_subnets, :security_group, :text
    add_column :azure_subnets, :route_table, :text

    add_column :azure_network_interfaces, :security_group, :text

    add_column :azure_availability_sets, :virtual_machines, :text, array: true, default: []
  end
end
