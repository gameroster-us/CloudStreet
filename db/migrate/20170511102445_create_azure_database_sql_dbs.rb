class CreateAzureDatabaseSQLDbs < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_sql_dbs, id: :uuid do |t|
      t.string :name, null: false
      t.string :location, null: false
      t.text :provider_id
      t.string :azure_resource_type, null: false
      t.string :kind
      t.string :edition
      t.string :status
      t.string :service_level_objective
      t.string :collation
      t.timestamp :creation_date
      t.string :default_secondary_location
      t.timestamp :earliest_restore_date
      t.string :elastic_pool_name
      t.integer :containment_state
      t.string :read_scale
      t.text :failover_group_id
      t.float :max_size

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true    
      t.uuid :region_id, index: true   
      t.uuid :subscription_id, index: true    
      t.uuid :resource_group_id, index:true

      t.uuid :CS_service_id

      t.timestamps
    end
    add_index :azure_sql_dbs, :adapter_id
    add_index :azure_sql_dbs, :subscription_id
    add_index :azure_sql_dbs, :resource_group_id
  end
end
