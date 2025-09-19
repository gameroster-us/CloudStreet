class CreateTenantServiceGroups < ActiveRecord::Migration[5.1]

  def change
    create_table :tenant_service_groups, id: :uuid do |t|
      t.uuid :tenant_id
      t.uuid :service_group_id

      t.timestamps
    end
    add_foreign_key :tenant_service_groups, :tenants
    add_foreign_key :tenant_service_groups, :service_groups
  end

end
