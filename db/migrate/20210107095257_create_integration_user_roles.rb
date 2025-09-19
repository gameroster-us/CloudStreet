class CreateIntegrationUserRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :integration_user_roles, id: :uuid do |t|
      t.uuid :integration_id
      t.uuid :user_role_id

      t.timestamps
    end
  end
end
