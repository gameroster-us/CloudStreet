class CreateSynchronization < ActiveRecord::Migration[5.1]
  def change
    create_table :synchronizations, id: :uuid do |t|
			t.uuid :account_id,  index: true
			t.uuid :region_id,  index: true
			t.uuid :adapter_id,  index: true
			t.string :provider
			t.string :provider_id
			t.string :service_type
			t.boolean :sync_up
			t.json :diff_data
			t.timestamps
    end
  end
end
