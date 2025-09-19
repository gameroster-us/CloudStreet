class AddImageDataToOrganisationImage < ActiveRecord::Migration[5.1]
  def change
    add_column :organisation_images, :image_data, :json
  end
end
