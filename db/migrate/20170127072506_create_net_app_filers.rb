class CreateNetAppFilers < ActiveRecord::Migration[5.1]
  def change
    create_table :filers, id: :uuid  do |t|
      t.json :data
      t.uuid :cloud_resource_adapter_id, index: true
      t.uuid :account_id, index: true
      t.string :type
      t.string :public_id
      t.string :name
      t.string :tenant_id

      t.timestamps
    end
  end
end
