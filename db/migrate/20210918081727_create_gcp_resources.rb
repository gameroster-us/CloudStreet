class CreateGCPResources < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_resources, id: :uuid do |t|
      t.string :name
      t.string :type
      t.string :provider_id
      t.json :provider_data, null: false, default: {}
      t.jsonb :data, null: false, default: {}
      t.string :error_message
      t.json :additional_properties, null: false, default: {}
      t.decimal :cost_by_hour, precision: 15, scale: 10, default: 0.0
      t.json :tags, array: true, default: []
      t.string :state
      t.boolean :idle_instance, default: false
      t.json :meter_data, array: true, default: []
      t.string :ignored_from, array: true, default: ['un-ignored'], null: false
      t.references :adapter, type: :uuid, foreign_key: true
      t.references :region, type: :uuid, foreign_key: true
      t.references :gcp_resource_zone, type: :uuid, foreign_key: true
      t.timestamps
    end
    add_index :gcp_resources, [:adapter_id, :gcp_resource_zone_id], name: "index_gcp_resource_on_adapter_id_and_resource_zone_id"
    add_index :gcp_resources, [:adapter_id, :gcp_resource_zone_id, :region_id], name: "index_gcp_resource_on_adapter_and_resource_zone_and_region"
  end
end
