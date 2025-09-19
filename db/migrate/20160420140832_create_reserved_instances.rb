class CreateReservedInstances < ActiveRecord::Migration[5.1]
  def change
    create_table :reserved_instances, id: :uuid  do |t|
      t.uuid :account_id
      t.uuid :region_id
      t.uuid :adapter_id
      t.string :availability_zone
      t.integer :duration
      t.float :fixed_price
      t.string :instance_type
      t.integer :instance_count
      t.string :product_description
      t.string :reserved_instances_id
      t.datetime :start_time
      t.string :state
      t.float :usage_price
      t.datetime :end_time
      t.json :data
      t.json :provider_data

      t.timestamps
    end
  end
end
