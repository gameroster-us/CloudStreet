class CreateStorage < ActiveRecord::Migration[5.1]
  def change
    create_table :storages , id: :uuid  do |t|
      t.string :key
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true
      t.uuid :account_id, index: true
      t.timestamp :creation_date
      t.timestamps
    end

  end
end
