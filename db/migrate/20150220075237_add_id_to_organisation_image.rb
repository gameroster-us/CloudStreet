class AddIdToOrganisationImage < ActiveRecord::Migration[5.1]
  def change
    add_column :organisation_images, :id, :primary_key
  end
end
