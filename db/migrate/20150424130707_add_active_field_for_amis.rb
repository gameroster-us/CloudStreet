class AddActiveFieldForAmis < ActiveRecord::Migration[5.1]
  def change
  	add_column :machine_images, :active, :boolean, default: true
  	add_column :organisation_images, :active, :boolean
  end
end
