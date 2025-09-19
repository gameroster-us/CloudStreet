class CreateAzureServices < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_services, id: :uuid do |t|
      t.string :name
      t.string :state
      t.string :desired_state
      t.json :data
      t.json :provider_data
      t.string :type
      t.uuid :vnet_ids, array: true, default: []
      t.json :geometry
      t.text :error_message
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true
      t.uuid :subscription_id, index: true
      t.uuid :account_id, index: true
      t.uuid :resource_group_id, index: true

      t.timestamps
    end
  end
end
