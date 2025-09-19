class CreateNacl < ActiveRecord::Migration[5.1]
  def change
    create_table :nacls, id: :uuid do |t|
      t.string :provider_id 
      t.string :provider_vpc_id
      t.string :name 
      t.uuid :vpc_id
      t.json :entries
      t.json :associations
      t.json :tags
      t.string :type
      t.uuid :adapter_id
      t.json :provider_data
      t.uuid :account_id, index: true
      t.uuid :region_id,  index: true

    end
  end
end