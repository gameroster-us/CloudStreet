class CreateOrganisationSamlUsers < ActiveRecord::Migration[5.1]
  def change
    create_table :organisation_saml_users, id: :uuid do |t|
      t.uuid :user_id
      t.uuid :organisation_id
      t.boolean :auto_assign_tenant, default: true
      t.boolean :auto_assign_role, default: true

      t.timestamps
    end
  end
end
