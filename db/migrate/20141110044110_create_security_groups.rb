class CreateSecurityGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :security_groups, id: :uuid do |t|
      t.string :name
      t.string :group_id
      t.string :owner_id
      t.string :type
      t.text :description
      t.text :ip_permissions
      t.json :provider_data
      t.uuid :vpc_id,     index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :region_id,  index: true

      t.timestamps
    end
  end
end
