class CreateServiceSynchronizationHistoryTable < ActiveRecord::Migration[5.1]
  def change
    drop_table :service_synchronization_histories
    create_table :service_synchronization_histories, id: :uuid  do |t|
      t.string :name
      t.string :state
      t.string :provider_type
      t.string :generic_type
      t.string :provider_id
      t.string :provider_vpc_id
      t.json :data
      t.json :provider_data
      t.json :updates
      t.uuid :adapter_id
      t.uuid :region_id
      t.uuid :account_id
      t.uuid :synchronization_id
      t.timestamps
    end
  end
end