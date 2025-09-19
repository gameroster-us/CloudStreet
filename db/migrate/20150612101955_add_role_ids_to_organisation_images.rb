class AddRoleIdsToOrganisationImages < ActiveRecord::Migration[5.1]
  def change
    add_column :organisation_images, :role_ids, :uuid, array: true, default: []
  end
end
  