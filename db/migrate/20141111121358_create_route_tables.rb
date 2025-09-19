class CreateRouteTables < ActiveRecord::Migration[5.1]
  def change
    create_table :route_tables, id: :uuid do |t|
      t.string :name
      t.string :provider_id
      t.string :type
      t.text :associations
      t.text :routes
      t.json :provider_data
      t.uuid :vpc_id,     index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id,  index: true

      t.timestamps
    end
  end
end
