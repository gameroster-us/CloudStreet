class ServiceSynchronizerAsync < CloudStreetServiceAsync
  def self.execute(options, &block)
  	# {:adapter_ids=>["3eeec25d-168f-42da-9dd0-eb76f4ec98d1"], :auto_sync_to_cs_from_aws=>"false", :user_id=>"9b5d1fb0-f946-4709-bd5c-c63ddc8b7abe"}
    adapters = Adapter.where(id: options[:adapter_ids], sync_running: false)
    unless adapters.empty?
      options[:adapter_ids] = adapters.pluck(:id)
      adapter = adapters.first
      adapters.update_all(sync_running: true)
      case adapter.type
      when CommonConstants::ADP_AWS
        SyncWorker.set(queue: 'sync').perform_async(options)
      when CommonConstants::ADP_GCP
        SyncWorker.set(queue: 'gcp_sync').perform_async(options)
      else
        SyncWorker.perform_async(options)
      end
    end
    status ServiceStatus, :success, options, &block
  end
end
