class AddForeignKeyDBCascadeToAzureServices < ActiveRecord::Migration[5.1]
  def up
    add_foreign_key(:azure_vnets, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_disks, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_load_balancers, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_network_interfaces, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_public_ip_addresses, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_resource_groups, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_route_tables, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_security_groups, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_sql_db_servers, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_sql_dbs, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_storage_accounts, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_subnets, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_virtual_machines, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:azure_availability_sets, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:CS_services, :adapters, column: 'adapter_id', on_delete: :cascade)
  end

  def down
    remove_foreign_key(:azure_vnets, name: 'azure_vnets_CS_service_id_fk')
    remove_foreign_key(:azure_disks, name: 'azure_disks_CS_service_id_fk')
    remove_foreign_key(:azure_load_balancers, name: 'azure_load_balancers_CS_service_id_fk')
    remove_foreign_key(:azure_network_interfaces, name: 'azure_network_interfaces_CS_service_id_fk')
    remove_foreign_key(:azure_public_ip_addresses, name: 'azure_public_ip_addresses_CS_service_id_fk')
    remove_foreign_key(:azure_resource_groups, name: 'azure_resource_groups_CS_service_id_fk')
    remove_foreign_key(:azure_route_tables, name: 'azure_route_tables_CS_service_id_fk')
    remove_foreign_key(:azure_security_groups, name: 'azure_security_groups_CS_service_id_fk')
    remove_foreign_key(:azure_sql_db_servers, name: 'azure_sql_db_servers_CS_service_id_fk')
    remove_foreign_key(:azure_sql_dbs, name: 'azure_sql_dbs_CS_service_id_fk')
    remove_foreign_key(:azure_storage_accounts, name: 'azure_storage_accounts_CS_service_id_fk')
    remove_foreign_key(:azure_subnets, name: 'azure_subnets_CS_service_id_fk')
    remove_foreign_key(:azure_virtual_machines, name: 'azure_virtual_machines_CS_service_id_fk')
    remove_foreign_key(:azure_availability_sets, name: 'azure_availability_sets_CS_service_id_fk')
    remove_foreign_key(:CS_services, name: 'CS_services_adapter_id_fk')
  end
end
