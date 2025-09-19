class AddIndexToAzureTables < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def up
  	add_index :azure_vnets, :id, algorithm: :concurrently unless index_exists?(:azure_vnets, :id)
	add_index :azure_subnets, :id, algorithm: :concurrently unless index_exists?(:azure_subnets, :id)
	add_index :azure_security_groups, :id, algorithm: :concurrently unless index_exists?(:azure_security_groups, :id)
	add_index :azure_route_tables, :id, algorithm: :concurrently unless index_exists?(:azure_route_tables, :id)
	add_index :azure_public_ip_addresses, :id, algorithm: :concurrently unless index_exists?(:azure_public_ip_addresses, :id)
	add_index :azure_network_interfaces , :id, algorithm: :concurrently unless index_exists?(:azure_network_interfaces, :id)
	add_index :azure_load_balancers, :id, algorithm: :concurrently unless index_exists?(:azure_load_balancers, :id)
	add_index :azure_storage_accounts, :id, algorithm: :concurrently unless index_exists?(:azure_storage_accounts, :id)
	add_index :azure_virtual_machines, :id, algorithm: :concurrently unless index_exists?(:azure_virtual_machines, :id)
	add_index :azure_availability_sets, :id, algorithm: :concurrently unless index_exists?(:azure_availability_sets, :id)
	add_index :azure_disks, :id, algorithm: :concurrently unless index_exists?(:azure_disks, :id)
	add_index :azure_resource_groups, :id, algorithm: :concurrently unless index_exists?(:azure_resource_groups, :id)
	add_index :azure_sql_db_servers, :id, algorithm: :concurrently unless index_exists?(:azure_sql_db_servers, :id)
	add_index :azure_sql_dbs, :id, algorithm: :concurrently unless index_exists?(:azure_sql_dbs, :id)
	add_index :filer_volumes, :id, algorithm: :concurrently unless index_exists?(:filer_volumes, :id)
	add_index :filer_volumes, :CS_service_id, algorithm: :concurrently unless index_exists?(:filer_volumes, :CS_service_id)
	add_index :azure_cost_summaries, :id, algorithm: :concurrently unless index_exists?(:azure_cost_summaries, :id)
	add_index :azure_cost_summaries, :CS_service_id, algorithm: :concurrently unless index_exists?(:azure_cost_summaries, :CS_service_id)
  end

  def down
  	remove_index :azure_vnets, :id if index_exists?(:azure_vnets, :id)
	remove_index :azure_subnets, :id if index_exists?(:azure_subnets, :id)
	remove_index :azure_security_groups, :id if index_exists?(:azure_security_groups, :id)
	remove_index :azure_route_tables, :id if index_exists?(:azure_route_tables, :id)
	remove_index :azure_public_ip_addresses, :id if index_exists?(:azure_public_ip_addresses, :id)
	remove_index :azure_network_interfaces , :id if index_exists?(:azure_network_interfaces, :id)
	remove_index :azure_load_balancers, :id if index_exists?(:azure_load_balancers, :id)
	remove_index :azure_storage_accounts, :id if index_exists?(:azure_storage_accounts, :id)
	remove_index :azure_virtual_machines, :id if index_exists?(:azure_virtual_machines, :id)
	remove_index :azure_availability_sets, :id if index_exists?(:azure_availability_sets, :id)
	remove_index :azure_disks, :id if index_exists?(:azure_disks, :id)
	remove_index :azure_resource_groups, :id if index_exists?(:azure_resource_groups, :id)
	remove_index :azure_sql_db_servers, :id if index_exists?(:azure_sql_db_servers, :id)
	remove_index :azure_sql_dbs, :id if index_exists?(:azure_sql_dbs, :id)
	remove_index :filer_volumes, :id if index_exists?(:filer_volumes, :id)
	remove_index :filer_volumes, :CS_service_id if index_exists?(:filer_volumes, :CS_service_id)
	remove_index :azure_cost_summaries, :id if index_exists?(:azure_cost_summaries, :id)
	remove_index :azure_cost_summaries, :CS_service_id if index_exists?(:azure_cost_summaries, :CS_service_id)
  end
end
