class CreateAWSRecords < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_records, id: :uuid do |t|
      t.json :data
      t.string :provider_vpc_id, index: true
      t.string :provider_id, index: true
      t.string :service_type, index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id, index: true
      t.timestamps
    end
  end
end