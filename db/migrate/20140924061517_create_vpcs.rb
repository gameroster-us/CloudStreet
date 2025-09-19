class CreateVpcs < ActiveRecord::Migration[5.1]
  def change
    create_table :vpcs , id: :uuid  do |t|
      t.string :name
      t.string :cidr
      t.string :vpc_id
      t.boolean :enable_dns_resolution
      t.boolean :internet_attached
      t.string :tenancy
      t.json :provider_data
      t.boolean :enabled
      t.uuid :template_id, index: true
      t.uuid :region_id, index: true
      t.uuid :account_id, index: true

      t.timestamps
    end
  end
end
