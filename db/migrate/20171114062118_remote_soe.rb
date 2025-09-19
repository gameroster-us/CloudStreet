class RemoteSoe < ActiveRecord::Migration[5.1]
  def up
    add_column :snapshots, :image_reference, :string
    execute("UPDATE snapshots snap SET image_reference =
 (select  regions.code || '-' || machine_images.image_id as image_reference FROM machine_images LEFT JOIN snapshots
  ON snapshots.machine_image_id=machine_images.id LEFT JOIN regions
  ON machine_images.region_id=regions.id 
 WHERE 
 machine_images.id=snap.machine_image_id limit 1);")

    add_column :organisation_images, :architecture, :string
    add_column :organisation_images, :description, :text
    add_column :organisation_images, :image_location, :string
    add_column :organisation_images, :image_type, :string
    add_column :organisation_images, :kernel_id, :string
    add_column :organisation_images, :platform, :string
    add_column :organisation_images, :ramdisk_id, :string
    add_column :organisation_images, :root_device_name, :string
    add_column :organisation_images, :root_device_type, :string
    add_column :organisation_images, :virtualization_type, :string
    add_column :organisation_images, :block_device_mapping, :text
    add_column :organisation_images, :image_owner_alias, :string
    add_column :organisation_images, :image_owner_id, :string
    add_column :organisation_images, :product_codes, :text
    add_column :organisation_images, :machine_image_name, :string
    add_column :organisation_images, :creation_date, :timestamp
    add_column :organisation_images, :is_public, :boolean
    add_column :organisation_images, :cost_by_hour, :decimal,:precision => 23, :scale => 18, default: 0.0
    add_column :organisation_images, :image_state, :string

    attributes = ["architecture",
      "description",
      "image_location",
      "image_type",
      "kernel_id",
      "platform",
      "ramdisk_id",
      "root_device_name",
      "root_device_type",
      "virtualization_type",
      "block_device_mapping",
      "image_owner_alias",
      "image_owner_id",
      "image_state",
      "product_codes",
      "creation_date",
      "cost_by_hour"]
    query = "UPDATE organisation_images org_img SET " 
    attributes.each do |key| 
      query.concat(" #{key}=(select machine_images.#{key} FROM machine_images INNER JOIN organisation_images
        ON organisation_images.machine_image_id=machine_images.id WHERE machine_images.id=org_img.machine_image_id limit 1),")
    end
    query = query.chomp(",")
    query.concat(";")
    execute(query)
    execute("UPDATE organisation_images org_img SET  machine_image_name=(select machine_images.name FROM machine_images INNER JOIN organisation_images ON organisation_images.machine_image_id=machine_images.id WHERE machine_images.id=org_img.machine_image_id limit 1);")
    execute("UPDATE organisation_images org_img SET  is_public=(select machine_images.is_public FROM machine_images INNER JOIN organisation_images ON organisation_images.machine_image_id=machine_images.id WHERE machine_images.id=org_img.machine_image_id limit 1)::boolean;")
    #TODOSOE
    # add_column :services, :machine_image_data, :json
    # sql = "UPDATE services SET machine_image_data=(
    #   select organisation_images.machine_image_name FROM organisation_images WHERE organisation_images.id=services.data -> 'image_config_id' limit 1);"
  end

  def down
    remove_column :snapshots, :image_reference, :string
    remove_column :organisation_images, :architecture
    remove_column :organisation_images, :description
    remove_column :organisation_images, :image_location
    remove_column :organisation_images, :image_type
    remove_column :organisation_images, :kernel_id
    remove_column :organisation_images, :platform
    remove_column :organisation_images, :ramdisk_id
    remove_column :organisation_images, :root_device_name
    remove_column :organisation_images, :root_device_type
    remove_column :organisation_images, :virtualization_type
    remove_column :organisation_images, :block_device_mapping
    remove_column :organisation_images, :image_owner_alias
    remove_column :organisation_images, :image_owner_id
    remove_column :organisation_images, :product_codes
    remove_column :organisation_images, :machine_image_name
    remove_column :organisation_images, :creation_date
    remove_column :organisation_images, :cost_by_hour
    remove_column :organisation_images, :is_public
    remove_column :organisation_images, :image_state
  end  
end
