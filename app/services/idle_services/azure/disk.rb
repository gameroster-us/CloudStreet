class IdleServices::Azure::Disk < IdleServices::Azure::AzureMetricFetcher
  DISK_TYPE_METRICS = {
    os_disk: ['OS Disk IOPS Consumed Percentage'],
    data_disk: ['Data Disk IOPS Consumed Percentage']
  }
  # in this method we pass VM objects as services
  # and later we fetch out attached disk from each vm
  def self.compute_idle_service(adapter, services, service_Klass='', data='')
    CSLogger.info "Idle state started of Disk(s) for adapter : #{adapter.name}"
    monitor_client = adapter.azure_monitor(adapter.subscription_id)
    update_services = []
    account = adapter.account
    disk_default_config = account.service_adviser_configs.azure_idle_disk_default_config
    idle_configs = disk_default_config.idle_conditions
    os_disk_configs = config_by_disk_type :os_disk, disk_default_config
    data_disk_configs = config_by_disk_type :data_disk, disk_default_config
    services.each do |vm_obj|
      begin
        # currently we are not showing OS disk on Service Advsier
        # so commenting the code of OS disk
        # idle_status = check_idle_status(vm_obj, monitor_client, os_disk_configs, nil)
        # disk = Azure::Resource::Compute::Disk.where("lower(provider_data->>'id')=lower(?)", vm_obj.os_disk['managed_disk']['id']&.downcase)
        #                                      .find_by(adapter_id: adapter.id)
        # update_idle_service_array(disk, update_services, idle_status)
        vm_obj.data_disks.each do |data_disk|
          begin
            lun = "LUN eq '#{data_disk['lun']}'"
            idle_status = check_idle_status(vm_obj, monitor_client, data_disk_configs, lun)
            disk = Azure::Resource::Compute::Disk.where("lower(provider_data->>'id')=lower(?)", data_disk['managed_disk']['id']&.downcase)
                                                 .find_by(adapter_id: adapter.id)
            update_idle_service_array(disk, update_services, idle_status)
            CSLogger.info "Checked idle disk conditions for disk - #{disk.try(:name)}"
          rescue
            next
          end
        end
      rescue StandardError => e
        CSLogger.error e.message
      end
    end
    update_services = update_services.compact.uniq(&:id)
    Azure::Resource::Compute::Disk.import update_services, on_duplicate_key_update: { conflict_target: [:id], columns: %i[idle_instance] }
    CSLogger.info "Idle state updated of #{update_services.length} Disk(s) for adapter : #{adapter.name}"
  rescue Adapters::InvalidAdapterError => e
    CSLogger.error "Invalid adapter credentials or permission for Adapters"
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

  def self.config_by_disk_type(disk_type, config_obj)
    return unless %i[data_disk os_disk].include?(disk_type)

    config_details = config_obj.config_details.deep_transform_keys(&:to_sym)
    config_details[:idle_conditions].select do |idle_config|
      idle_config.merge!(config_details.slice(:metric_duration_hours, :metric_interval_minutes))
      DISK_TYPE_METRICS[disk_type].include?(idle_config[:metric])
    end
  end
end
