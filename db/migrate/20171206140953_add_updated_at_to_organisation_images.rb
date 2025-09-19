class AddUpdatedAtToOrganisationImages < ActiveRecord::Migration[5.1]
  def self.up
    add_column :organisation_images, :updated_at, :timestamp
    OrganisationImage.update_all(updated_at: Time.now.utc)
  end

  def self.down
    remove_column :organisation_images, :updated_at
  end  
end
