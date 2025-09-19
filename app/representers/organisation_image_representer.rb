module OrganisationImageRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  property :id
  property :organisation_image_id, getter: lambda{|args| self.id }
  property :image_name
  property :display_name, getter: lambda{|args| self.image_name }
  property :architecture
  property :block_device_mapping
  property :userdata
  property :user_role_ids
  property :description
  property :image_id
  property :creation_date, getter: lambda { |args| self.creation_date.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :image_location
  property :adapter_id
  property :adapter_name
  property :image_state
  property :image_type
  property :image_owner_alias
  property :image_owner_id
  property :image_region_name
  property :product_codes
  property :is_public
  property :kernel_id
  property :platform
  property :ramdisk_id
  property :root_device_name
  property :root_device_type
  property :virtualization_type
  property :region_id
  property :group_name
  property :active
  property :group_images, if: lambda{|args| args[:options][:with_group_images].eql?(true) }
  property :ejectable
  property :errors, getter: lambda {|*| self.errors.present? }
  property :error_messages, getter: lambda{|*| self.errors.messages }
  collection(
    :machine_image_configurations,
    class: MachineImageConfiguration,
    extend: MachineImageConfigurationRepresenter,
    if: lambda{|args| args[:options][:with_configs].eql?(true)}
  )

  def image_region_name
    self.region.region_name
  end

end
