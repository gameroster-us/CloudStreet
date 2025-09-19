class CreateGCPResourceZones < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_resource_zones, id: :uuid do |t|
      t.string :zone_name
      t.string :code
      t.references :region, type: :uuid, foreign_key: true
      t.uuid :adapter_id, index: true

      t.timestamps
    end
  end
end
