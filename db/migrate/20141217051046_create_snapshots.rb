class CreateSnapshots < ActiveRecord::Migration[5.1]
  def change
    create_table :snapshots, id: :uuid do |t|
      t.string :name
      t.string :type
      t.string :category
      t.string :provider_id
      t.json :provider_data
      t.text :description
      t.uuid :account_id, index: true
      t.uuid :service_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true

      t.timestamps
    end
  end
end
