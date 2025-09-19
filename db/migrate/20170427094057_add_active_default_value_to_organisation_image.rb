class AddActiveDefaultValueToOrganisationImage < ActiveRecord::Migration[5.1]
  def up
  	change_column :organisation_images, :active, :boolean, :default => true
  	OrganisationImage.where(active: nil).update_all(active: true)
  end

  def down
  	change_column :organisation_images, :active, :boolean
  end
end
