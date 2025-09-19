class CreateOrganisationServiceGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :organisation_service_groups, id: :uuid do |t|
      t.uuid :organisation_id
      t.uuid :service_group_id

      t.timestamps
    end

    add_foreign_key :organisation_service_groups, :organisations
    add_foreign_key :organisation_service_groups, :service_groups
    add_index :organisation_service_groups, [:organisation_id, :service_group_id], name: 'index_child_org_on_org_and_service_groups'
    add_index :organisation_service_groups, :service_group_id
  end
end
