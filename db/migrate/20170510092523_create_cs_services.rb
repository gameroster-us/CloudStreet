class CreateCSServices < ActiveRecord::Migration[5.1]
  def change
    create_table :CS_services, id: :uuid do |t|

      t.string :name, null: false
      t.string :service_type, null: false, index: true
      t.string :state, null: false, index: true
      t.text :provider_id, null: false

      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true
      t.uuid :subscription_id, index: true
      
      t.timestamps
    end
    add_index :CS_services, :adapter_id
    add_index :CS_services, :state
    add_index :CS_services, :service_type
    add_index :CS_services, :region_id
    add_index :CS_services, :subscription_id
    
  end
end
