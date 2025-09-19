class CreateSubnetGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :subnet_groups, id: :uuid do  |t|
      t.string :name
      t.string :provider_id
      t.text :description
      t.string :state
      t.uuid :account_id
      t.uuid :region_id
      t.uuid :adapter_id
      t.uuid :vpc_id
      t.text :subnet_ids, array: true, default: []
      t.json :data
      t.json :provider_data
      t.string :type
      t.text :subnet_service_ids, array: true, default: []

      t.timestamps
    end
  end
end
