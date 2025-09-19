class AddCurrentTenantToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :current_tenant, :uuid
    add_index :users, :current_tenant
  end
end
