class GCP::RemoteResourceObject::Compute::Disk < Struct.new(:provider_data, :name, :provider_id, :tags, :disk_status, :size_gb, :disk_type, :source_image, :source_image_id)

  include Azure::RemoteResourceObject::Utils::TagParser
  # Below is the vm status can be
  STATE = { 'CREATING' => 'creating', 'RESTORING' => 'restoring', 'READY' => 'ready', 'FAILED' => 'failed', 'DELETING' => 'deleting' }
  DISK_STORAGE_TYPE = { 'pd-standard' => 'Standard persistent', 'pd-balanced' => 'Balanced persistent', 'pd-ssd' => 'SSD persistent', 'pd-extreme' => 'Extreme persistent' }

  def get_resource_table_attributes(location_type)
    dsk_type = get_disk_type()
    dsk_storage_type = get_disk_storage_type()
    dsk_state = get_disk_state()
    dsk_vm = get_disk_vm()
   {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      tags: parse_tags,
      disk_type: dsk_type,
      disk_storage_type: dsk_storage_type,
      disk_size_gb: size_gb,
      state: STATE[disk_status],
      source_image: source_image,
      source_image_id: source_image_id,
      disk_state: dsk_state,
      disk_vm: dsk_vm,
      location_type: location_type
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data['name'],
      data['id'],
      (data['labels'] || {}),
      data['status'],
      data['sizeGb'],
      (data['type'] || {}),
      (data['sourceImage'] || {}),
      (data['sourceImageId'] || {})
    )
  end

  def get_disk_type()
    disk_type.split('diskTypes/').last
  end

  def get_disk_storage_type()
    dk_type = get_disk_type
    DISK_STORAGE_TYPE[dk_type]
  end

  def get_disk_state()
    provider_data.key?('users') ? 'Attached' : 'Unattached'
  end

  def get_disk_vm()
    get_disk_state == 'Attached' ? provider_data['users'].first.split('instances/').last : ''
  end
end