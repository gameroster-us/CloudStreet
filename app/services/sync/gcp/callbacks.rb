# GCP SYNC All callbacks
module Sync::GCP::Callbacks
  class MainSyncCallback
    def on_complete(status, options)
      CSLogger.info "Step 13 GCP MainSyncCallback on_complete | acc - #{options['account_id']} | sync_id - #{options['synchronization_id']}"
      synchronization = Synchronization.find(options['synchronization_id'])
      synchronization.log_sync_complete

      @synchronizer = ServiceSynchronizer.new(options['account_id'])
      @synchronizer.sync_progress_complete(synchronization.adapter_ids)
      adapters = Adapters::GCP.where(id: synchronization.adapter_ids)
      adapter_data = {
        adapter_id: synchronization.adapter_ids.first,
        adapter_name: adapters.map(&:name).join(', '),
        provider_type: 'GCP'
      }
      if !options['back_ground_job']
        @synchronizer.alert_sync_complete(options['synchronization_id'], adapter_data)
      end
      args = { adapter_id: synchronization.adapter_ids, account_id: options["account_id"] }
      if ::Synchronization::AUTO_SYNC_QUEUES.include?(options['queue_name'])
        ServiceManagerSummaryDataSaverWorker.set(queue: options["queue_name"]).perform_async(args)
        ServiceAdviserSummaryDataSaverWorker.set(queue: options["queue_name"]).perform_async(options["account_id"], nil, { adapter_id: synchronization.adapter_ids })
      else
        ServiceManagerSummaryDataSaverWorker.perform_async(args)
        ServiceAdviserSummaryDataSaverWorker.perform_async(options["account_id"], nil, { adapter_id: synchronization.adapter_ids }, options['synchronization_id'])
      end
      CSLogger.info "Step 13 GCP MainSyncCallback completed | adapter_names #{adapters.map(&:name).join(', ')}"
    end

    def on_success(status, options)
      CSLogger.info "GCP MainSyncCallback Success"
    end
  end

  class IdleServiceCallback

    def on_complete(status, options)
      CSLogger.info "GCP Idle service updated completed"
      # if options["queue_name"].present?
        # SecurityScanners::Azure::SecurityScanStorerWorker.set(queue: options["queue_name"]).perform_async(options['account_id'], options['adapter_id'])
      # else
        # SecurityScanners::Azure::SecurityScanStorerWorker.perform_async(options['account_id'], options['adapter_id'])
      # end
    end

    def on_success(status, options)
      CSLogger.info "GCP Idle service updated successfully"
    end

  end

  class CostUpdaterCallbacks
    def on_complete(status, options)
      CSLogger.info "Complete GCP resources cost updated successfully | Adapter id: #{options['adapter_id']}"
      Sidekiq::Batch.new(options['batch_id']).jobs do
        idle_service_batch = Sidekiq::BatchCreator.call(GCP::DataManager::IdleServiceCallback, options, 'Idle service consideration')
        idle_service_batch.jobs do
          if options["queue_name"].present?
            GCP::Idle::FetchIdleServicesDataWorker.set(queue: "background_gcp_idle_queue").perform_async(options)
          else
            GCP::Idle::FetchIdleServicesDataWorker.perform_async(options)
          end
        end
      end
    end

    def on_success(status, options)
      CSLogger.info "Success GCP resources cost updated successfully | Adapter id: #{options['adapter_id']}"
    end
  end

  class AdapterSyncCallback

    def on_complete(status, options)
      CSLogger.info "Step 12 GCP AdapterSyncCallback on_complete | adp_id - #{options['adapter_id']}"
      failed = false
      adapter = Adapter.find_by_id(options['adapter_id'])
      synchronizer = ServiceSynchronizer.new(options['account_id'])
      synchronization = Synchronization.find(options['synchronization_id']) if options['synchronization_id'].present?
      if status.failures != 0
        CSLogger.error 'Uh oh, batch has failures'
        CSLogger.error status.failures.inspect
        CSLogger.error "STEP 12 GCP AdapterSyncCallback status failed for adapter : #{options['adapter_id']} (#{adapter.try(:name)})"
        failed = true
      else
        costable_groups = GCP::Resource.where(type: GCP::Resource::COSTABLE_SERVICES, adapter_id: adapter.id).active.group_by(&:type)
        # If else is done bcuz when no costable service is present thn callback is not initiated on sync & bg!!
        if costable_groups.present?
          Sidekiq::Batch.new(options['batch_id']).jobs do
            cost_updater_batch = Sidekiq::BatchCreator.call(GCP::DataManager::CostUpdaterCallbacks, options, 'Updating Adapter Resource Costing GCP')
            cost_updater_batch.jobs do
              costable_groups.each do |klass, resources|
                options[:gcp_resource_ids] = resources.map(&:id)
                options[:klass] = klass
                if options["queue_name"].present?
                  GCP::CostUpdaterWorker.set(queue: "background_gcp_idle_queue").perform_async(options.dup)
                else
                  GCP::CostUpdaterWorker.perform_async(options.dup)
                end
              end
            end
          end
        else
          Sidekiq::Batch.new(options['batch_id']).jobs do
            idle_service_batch = Sidekiq::BatchCreator.call(GCP::DataManager::IdleServiceCallback, options, 'Idle service consideration')
            idle_service_batch.jobs do
              if options["queue_name"].present?
                GCP::Idle::FetchIdleServicesDataWorker.set(queue: "background_gcp_idle_queue").perform_async(options)
              else
                GCP::Idle::FetchIdleServicesDataWorker.perform_async(options)
              end
            end
          end
        end
        synchronizer.mark_sync_complete(options['adapter_id'])
        synchronization&.mark_adapter_wise_sync_status_gcp(options['adapter_id'], Synchronization::SUCCESS)
        CSLogger.info "Step 12 AdapterSyncCallback sync success | adp_id - #{options['adapter_id']} | adp_name - #{adapter.try(:name)}"
      end
    rescue StandardError => e
      CSLogger.error "ISSUE HERE Step 12 AdapterSyncCallback | Error - #{e.message} | adp_id - #{options['adapter_id']}"
      CSLogger.error e.backtrace
      failed = true
    ensure
      if failed
        synchronizer.failed(options['account_id'], options['adapter_id'])
        synchronization&.mark_adapter_wise_sync_status_gcp(options['adapter_id'], Synchronization::FAILED)
      end
      CSLogger.info 'Step 12 AdapterSyncCallback setting sync_running state to false'
      adapter.update_attribute(:sync_running, false) if adapter.present?
    end

    def on_success(status, options) end
  end

  class ResourceFetcherCallback
    def on_complete(status, options)
      CSLogger.info "Step 9 GCP ResourceFetcherCallback on complete | adp_id - #{options['adapter_id']} | region_id #{options['region_id']} | region_name - #{options['region_name']}"
      region_names_count = options['region_names'].count
      unit_percent = (100.to_f / region_names_count).round(2)
      completed_count = options['region_names'].index(options['region_name']) + 1
      adapter_data = {
        id: options['adapter_id'],
        name: options['adapter_name'],
        sync_state: Synchronization::RUNNING,
        total_count: region_names_count,
        pending: region_names_count - completed_count,
        completed_count: completed_count,
        phase: 2,
        start_percentage: (unit_percent - 1) * completed_count,
        end_percentage: unit_percent * completed_count
      }
      CSLogger.info "Step 9 again GCP ResourceFetcherCallback on complete | adp_id - #{options['adapter_id']} | region_id #{options['region_id']} | region_name - #{options['region_name']} | adapter_data - #{adapter_data}"

      ::NodeManager.send_sync_progress(options['account_id'], [adapter_data])
      Sidekiq::Batch.new(status.parent_bid).jobs do
        conn_builder_batch = Sidekiq::BatchCreator.call(GCP::DataManager::ConnectionBuilderCallback, options, 'GCP resource primary connection builder')
        conn_builder_batch.jobs do
          if options['queue_name'].present?
            Sync::GCP::Resource::ConnectionBuilderWorker.set(queue: options['queue_name']).perform_async(options['adapter_id'], options['region_id'], options['enabled_region_ids'])
          else
            Sync::GCP::Resource::ConnectionBuilderWorker.perform_async(options['adapter_id'], options['region_id'], options['enabled_region_ids'])
          end
        end
      end
    rescue StandardError => e
      CSLogger.error "ISSUE HERE Step 9 ResourceFetcherCallback | Error - #{e.message} | adp_id - #{options['adapter_id']} | region_id #{options['region_id']}"
      CSLogger.error e.backtrace
    end

    def on_success(status, options) end

  end

  class ConnectionBuilderCallback
    def on_complete(status, options)
      CSLogger.info "Step 11 GCP connection builder completed | adp_id : #{options['adapter_id']} | region_id #{options['region_id']}"
      failed = false
      adapter = Adapter.find_by_id(options['adapter_id'])
      synchronizer = ServiceSynchronizer.new(options['account_id'])
      synchronization = Synchronization.find(options['synchronization_id']) if options['synchronization_id'].present?

      if status.failures != 0
        CSLogger.error 'Uh oh, batch has failures'
        CSLogger.error status.failures.inspect
        failed = true
      end
      CSLogger.info "Step 11 again GCP connection builder completed | adp_id : #{options['adapter_id']} | adp_name - #{adapter && adapter.name} | region_name - #{options['region_name']}"
    rescue StandardError => e
      CSLogger.error "ISSUE HERE Step 11 ConnectionBuilderCallback | Error - #{e.message} | adp_id - #{options['adapter_id']} | | region_id #{options['region_id']}"
      CSLogger.error e.backtrace
      failed = true
    ensure
      if failed
        synchronizer.failed(options['account_id'], options['adapter_id'])
        synchronization&.mark_adapter_wise_sync_status_gcp(options['adapter_id'], Synchronization::FAILED)
        adapter.update_attribute(:sync_running, false)
      end
    end

    def on_success(status, options) end
  end

  class GCPAccountAutoSyncCallback
    def on_complete(status, options)
      CSLogger.info "GCPAccountAutoSyncCallback on_complete | account_id - #{options['account_id']}"
      uniq_account_ids = Adapters::GCP.gcp_normal_active_adapters.for_active_accounts.where.not(account_id: options['account_id']).map(&:account_id).uniq
      exclude_account_ids = []
      exclude_account_ids << options['account_id']
      uniq_account_id = uniq_account_ids.first
      exclude_account_ids << uniq_account_id
      if uniq_account_id.present?
        options['account_id'] = exclude_account_ids.flatten
        account_jobs = Sidekiq::BatchCreator.call(AutoSyncWorker::GCPAutoSyncWorker::GCPAccountAutoSyncCallback, options, "GCP Account AutoSync Callback | acc - #{uniq_account_id}")
        account_jobs.jobs do
          AutoSyncWorker::GCPAccountAutoSyncWorker.set(queue: 'background_gcp_sync').perform_async(uniq_account_id)
        end
      else
        CSLogger.info 'GCPAccountAutoSyncCallback full complete for all account ids'
      end
    end

    def on_success(status, options)
    end
  end
end
