class CreateSynchronizationHistory < ActiveRecord::Migration[5.1]
  def change
    create_table :service_synchronization_histories,id: :uuid do |t|
      t.string :service_type
      t.string :provider_id
      t.string :provider
      t.json :sync_data
      t.uuid :synchronization_id
      t.uuid :region_id
      t.uuid :adapter_id
      t.uuid :account_id
    end
  end
end
