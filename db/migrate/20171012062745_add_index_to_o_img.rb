class AddIndexToOImg < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  def up
  	add_index :machine_image_groups, :id, algorithm: :concurrently unless index_exists?(:machine_image_groups, :id)
  	add_index :organisation_images, :id, algorithm: :concurrently unless index_exists?(:organisation_images, :id)
    add_index :organisation_images, :region_id, algorithm: :concurrently unless index_exists?(:organisation_images, :region_id)
    add_index :organisation_images, :machine_image_group_id, algorithm: :concurrently unless index_exists?(:organisation_images, :machine_image_group_id)
    add_index :organisation_images, :machine_image_id, algorithm: :concurrently unless index_exists?(:organisation_images, :machine_image_id)
  end

  def down
  	remove_index :machine_image_groups, :id if index_exists?(:machine_image_groups, :id)
  	remove_index :organisation_images, :id if index_exists?(:organisation_images, :id)
    remove_index :organisation_images, :region_id if index_exists?(:organisation_images, :region_id)
    remove_index :organisation_images, :machine_image_group_id if index_exists?(:organisation_images, :machine_image_group_id)
    remove_index :organisation_images, :machine_image_id if index_exists?(:organisation_images, :machine_image_id)
  end
end
