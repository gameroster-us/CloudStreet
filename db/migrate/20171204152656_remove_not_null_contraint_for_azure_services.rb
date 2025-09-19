class RemoveNotNullContraintForAzureServices < ActiveRecord::Migration[5.1]
  def change

  	#vm
  	change_column_null :azure_virtual_machines, :publisher, true
  	change_column_null :azure_virtual_machines, :offer, true
  	change_column_null :azure_virtual_machines, :sku, true
  	change_column_null :azure_virtual_machines, :version, true
  	change_column_null :azure_virtual_machines, :azure_resource_type, true

  	#vnet
  	change_column_null :azure_vnets, :azure_resource_type, true
  	change_column_null :azure_vnets, :address_prefixes, true

  	#subnet
  	change_column_null :azure_subnets, :azure_resource_type, true
  	change_column_null :azure_subnets, :address_prefix, true

    #sg
    change_column_null :azure_security_groups, :azure_resource_type, true

    #rt
    change_column_null :azure_route_tables, :azure_resource_type, true

    #nic
    change_column_null :azure_network_interfaces, :azure_resource_type, true
    
    #public_ip
    change_column_null :azure_public_ip_addresses, :azure_resource_type, true

    #lb
    change_column_null :azure_load_balancers, :azure_resource_type, true

    #availabilty set
    change_column_null :azure_availability_sets, :azure_resource_type, true
    change_column_null :azure_availability_sets, :update_domain_count, true
    change_column_null :azure_availability_sets, :fault_domain_count, true
    
    #disk
    change_column_null :azure_disks, :azure_resource_type, true
    change_column_null :azure_disks, :create_option, true

    #storage acc
    change_column_null :azure_storage_accounts, :azure_resource_type, true
    change_column_null :azure_storage_accounts, :sku_name, true
    change_column_null :azure_storage_accounts, :sku_tier, true

    #db
    change_column_null :azure_sql_dbs, :azure_resource_type, true

    #db servers
    change_column_null :azure_sql_db_servers, :azure_resource_type, true
  end
end
