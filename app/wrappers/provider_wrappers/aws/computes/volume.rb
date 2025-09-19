class ProviderWrappers::AWS::Computes::Volume < ProviderWrappers::AWS
  def fetch_remote_volume(volume_id)
    ProviderWrappers::AWS.retry_on_timeout{
      agent.volumes.get(volume_id) if volume_id
    }
  end

  def create_backup(volume_id, options)
    ProviderWrappers::AWS.retry_on_timeout{
      @agent.create_snapshot(volume_id, options[:target_description]).data[:body]["snapshotId"]
    }
  end

  def update(update_params)
    update_remote_volume(update_params["service_attribute"])
  end

  def fetch_volume_modifications(provider_id)
    volume = agent.describe_volumes_modifications({'volume-id' => provider_id}).data[:body]['volumeModificationSet'][0]
    { modification_state: volume['modificationState'], progress: volume['progress'] }
  end

  def update_volumes_modifications
    results = agent.describe_volumes_modifications.data[:body]['volumeModificationSet']
    services = Service.where(provider_id: results.map{ |vol| vol['volumeId']})
    services.each do |service|
      result = results.detect { |rs| rs['volumeId'] == service.provider_id }
      service.modification_info = { modification_state: result['modificationState'], progress: result['progress'] }
      service.save
    end
  end

  def getAttributeName(key)
    case key
      when 'volume_type'
        return "VolumeType"
      when 'size'
        return "Size"
      when 'iops'
        return "Iops"
      else "No match found"
    end
  end

  def getAttributeValue(value)
    case value
      when 'Provisioned IOPS SSD (IO1)', 'Provisioned IOPS SSD'
        'io1'
      when 'General Purpose SSD (GP2)', 'General Purpose SSD'
        'gp2'
      when 'Cold HDD (SC1)', 'Cold HDD'
        'sc1'
      when 'Throughput Optimized HDD (ST1)', 'Throughput Optimized HDD'
        'st1'
      else
        value
    end
  end

  def update_remote_volume(params)
    if service.provider_id.present?
      updated_server_attrs = {}
      CSLogger.info(">>>>>>>>>>>>>>>>> params #{params}")
      params.each do |key, value|
        updated_server_attrs[getAttributeName(key)] = getAttributeValue(value) unless key == 'id'
      end
      CSLogger.info("updated_server_attrs: #{updated_server_attrs}")
      agent.modify_volume(service.provider_id, updated_server_attrs)
    end
  end
end
