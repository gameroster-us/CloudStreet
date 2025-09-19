class CreateSubnet < ActiveRecord::Migration[5.1]
  def change
    create_table :subnets, id: :uuid do |t|
      t.string :provider_id 
      t.string :provider_vpc_id
      t.string :name 
      t.uuid :vpc_id
      t.text :cidrblock
      t.integer :availableip
      t.string :availability
      t.json :tags
      t.string :type
      t.json :provider_data
      t.uuid :adapter_id
      t.uuid :account_id, index: true
      t.uuid :region_id,  index: true
    end
  end
end