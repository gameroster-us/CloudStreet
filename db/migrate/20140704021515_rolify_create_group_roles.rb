class RolifyCreateGroupRoles < ActiveRecord::Migration[5.1]
  def change
    create_table(:group_roles, :id => :uuid) do |t|
      t.string :name
      t.references :resource, :polymorphic => true

      t.timestamps
    end

    create_table(:groups_roles, :id => false) do |t|
      t.references :group
      t.references :group_role
    end

    # Change all the damn fields to UUID
    change_column :group_roles,  :resource_id, "uuid USING null"
    change_column :groups_roles, :group_id, "uuid USING null"
    change_column :groups_roles, :group_role_id, "uuid USING null"
  end
end
