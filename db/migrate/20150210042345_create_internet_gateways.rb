class CreateInternetGateways < ActiveRecord::Migration[5.1]
  def change
    create_table :internet_gateways, id: :uuid do |t|
      t.string :name
      t.string :state
      t.string :type
      t.string :provider_id, index: true
      t.json :provider_data
      t.uuid :vpc_id,     index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id,  index: true

      t.timestamps
    end
  end
end
