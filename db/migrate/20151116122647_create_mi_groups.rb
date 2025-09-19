class CreateMiGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :machine_image_groups , id: :uuid  do |t|
      t.string :name
      t.string :match_key
      t.string :virtualization_type
      t.string :image_owner_alias
      t.string :root_device_type
      t.string :image_owner_id
      t.string :architecture
      t.string :image_type
      t.string :is_public
      t.string :platform
      t.index :name, :unique => true
      t.uuid :region_id, index: true
      t.timestamps
    end

    add_column(:machine_images, :machine_image_group_id, :uuid)
    add_column(:organisation_images, :machine_image_group_id, :uuid)
    add_column(:organisation_images, :ejectable, :boolean, :default => true)
    add_index :machine_image_groups, [:match_key, :region_id], :unique => true
    # change_column_null(:machine_images, :mi_group_id, false)
    change_column_null :organisation_images, :ejectable, false
  end
end
