class GCP::RemoteResourceObject::Compute::Snapshot < Struct.new(:provider_data, :name, :provider_id, :tags, :state, :creation_date, :storage_locations, :source_disk, :source_disk_id, :disk_size_gb, :auto_created, :storage_bytes)

  include Azure::RemoteResourceObject::Utils::TagParser

  # Below is the Snapshot status can be
  STATE = { 'CREATING' => 'creating', 'DELETING' => 'deleting', 'FAILED' => 'failed', 'READY' => 'ready', 'UPLOADING' => 'uploading' }

  def get_resource_table_attributes(location_type)
    optimised_source_disk = get_source_disk(source_disk)
    creation_type = get_creation_type(auto_created)
    converted_storage_bytes = fetch_storage_bytes_in_gb(storage_bytes.to_i)
    {
      name: name,
      provider_id: provider_id,
      provider_data: provider_data,
      state: STATE[state],
      tags: parse_tags,
      creation_date: creation_date,
      source_disk: optimised_source_disk,
      source_disk_id: source_disk_id,
      disk_size_gb: disk_size_gb,
      creation_type: creation_type,
      location_type: location_type,
      snapshot_size_gb: converted_storage_bytes
    }
  end

  def self.parse_from_json(data)
    new(
      data,
      data['name'],
      data['id'],
      (data['labels'] || {}),
      data['status'],
      data['creationTimestamp'],
      data['storageLocations'],
      (data['sourceDisk'] || ''),
      (data['sourceDiskId'] || ''),
      (data['diskSizeGb'] || ''),
      (data['autoCreated'] || false),
      data['storageBytes']
    )
  end

  def get_source_disk(source_disk)
    source_disk.split('disks/').last
  end

  def get_creation_type(auto_created)
    auto_created ? 'Scheduled' : 'Manual'
  end

  def fetch_storage_bytes_in_gb(storage_bytes)
    (storage_bytes/(1024.0*1024.0*1024.0)).round(5)
  end
end
