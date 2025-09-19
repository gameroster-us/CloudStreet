class ChangeOrganisationImagesColumns < ActiveRecord::Migration[5.1]
  def self.up
  	rename_table :accounts_machine_images, :organisation_images
	  add_column :organisation_images, :image_id, :string
    add_column :organisation_images, :region_id, :uuid
	  add_column :organisation_images, :instance_types, :text
	  add_column :organisation_images, :image_name, :text
  end

  def self.down
  	 remove_column :organisation_images, :image_id
     remove_column :organisation_images, :region_id
  	 remove_column :organisation_images, :instance_types
  	 remove_column :organisation_images, :image_name
  	 rename_table :organisation_images, :accounts_machine_images
  end
end

