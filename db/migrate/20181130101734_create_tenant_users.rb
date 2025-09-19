class CreateTenantUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :tenant_users, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :tenant_id

      t.timestamps
    end
    add_foreign_key :tenant_users, :users
    add_foreign_key :tenant_users, :tenants
    add_index :tenant_users, [:user_id, :tenant_id]
    add_index :tenant_users, [:tenant_id, :user_id]
  end
end
