module MachineImageArchiverBatchCallback
  class MachineImageArchiver
    def on_complete(status, options)
      if status.failures != 0
        CSLogger.info 'Machine Image Archiver Callback, batch has failures'
      else
        CSLogger.info "-------- Machine Image Archiver Callback ---------------"
        adapter = Adapter.find(options['adapter_id'])
        SnapshotRetentionWorker.new.instance_eval { delete_ebs_volume_snapshot(adapter, options['region_code'], options['not_root_volume'], true) }
      end
    end

    def on_success(status, options)
      CSLogger.info 'Machine Image Archiver Finished'
    end
  end
end
