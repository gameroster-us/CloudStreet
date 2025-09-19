class CreateAzureResources < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_resources, id: :uuid do |t|
      t.string :name
      t.string :type
      t.string :provider_id
      t.references :adapter, type: :uuid, foreign_key: true
      t.references :region, type: :uuid, foreign_key: true
      t.json :provider_data, null: false, default: {}
      t.jsonb :data, null: false, default: {}
      t.string :error_message
      t.json :additional_properties, null: false, default: {}
      t.decimal :cost_by_hour, precision: 15, scale: 10, default: 0.0
      t.json :tags, array: true, default: []

      t.timestamps
    end
  end
end
