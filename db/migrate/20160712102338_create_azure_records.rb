class CreateAzureRecords < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_records, id: :uuid do |t|
      t.json :data
      t.uuid :vnet_id, index: true
      t.string :service_type, index: true
      t.string :type
      t.string :resource_group_name
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true
      t.uuid :subscription_id, index: true
      t.uuid :account_id, index: true

      t.timestamps
    end
  end
end
