class AddDependsOnFieldToAllAzureServiceTables < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_vnets, :depends_on, :string, array: true, default: []
    add_column :azure_subnets, :depends_on, :string, array: true, default: []
    add_column :azure_security_groups, :depends_on, :string, array: true, default: []
    add_column :azure_route_tables, :depends_on, :string, array: true, default: []
    add_column :azure_public_ip_addresses, :depends_on, :string, array: true, default: []
    add_column :azure_network_interfaces, :depends_on, :string, array: true, default: []
    add_column :azure_load_balancers, :depends_on, :string, array: true, default: []
    add_column :azure_availability_sets, :depends_on, :string, array: true, default: []
    add_column :azure_virtual_machines, :depends_on, :string, array: true, default: []
    add_column :azure_sql_dbs, :depends_on, :string, array: true, default: []
    add_column :azure_sql_db_servers, :depends_on, :string, array: true, default: []
    add_column :azure_storage_accounts, :depends_on, :string, array: true, default: []
    add_column :azure_disks, :depends_on, :string, array: true, default: []
  end
end
