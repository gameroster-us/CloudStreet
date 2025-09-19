class AddedMissingMigrationAzure < ActiveRecord::Migration[5.1]
  def change

    add_column :azure_virtual_machines, :operating_system , :string
    add_column :azure_virtual_machines, :diagnostics_profile , :json
    add_column :azure_network_interfaces, :dns_servers , :json
    add_column :azure_network_interfaces, :applied_dns_servers , :string
    add_column :azure_network_interfaces, :mac_address , :string
    add_column :azure_sql_dbs, :max_size_bytes , :string
    add_column :azure_sql_dbs, :sample_name , :string
    add_column :azure_sql_db_servers, :fully_qualified_domain_name , :string
    add_column :azure_sql_db_servers, :administrator_login , :string
    add_column :azure_sql_db_servers, :external_administrator_login , :string
    add_column :azure_sql_db_servers, :external_administrator_sid , :string
    add_column :azure_sql_db_servers, :version , :string
    add_column :azure_sql_db_servers, :db_server_state , :string
    add_column :azure_load_balancers, :lb_type , :string
    add_column :azure_public_ip_addresses, :domain_name_label , :string
   
  end
end
