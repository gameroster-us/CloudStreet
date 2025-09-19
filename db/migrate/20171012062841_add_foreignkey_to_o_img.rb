class AddForeignkeyToOImg < ActiveRecord::Migration[5.1]
  def up
  	claen_orphan
  	add_foreign_key :organisation_images, :machine_images, on_delete: :cascade
    add_foreign_key :organisation_images, :machine_image_groups, on_delete: :cascade
  end

  def down
  	remove_foreign_key :organisation_images, :machine_images
    remove_foreign_key :organisation_images, :machine_image_groups
  end

  def claen_orphan
  	      OrganisationImage.joins('LEFT JOIN machine_images ON organisation_images.machine_image_id = machine_images.id').where('machine_images.id IS NULL').delete_all
      OrganisationImage.joins('LEFT JOIN machine_image_groups ON organisation_images.machine_image_group_id = machine_image_groups.id').where('machine_image_groups.id IS NULL').delete_all
  end
end
