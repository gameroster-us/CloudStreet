# Resource Regional Fetcher worker
module Sync
  module GCP
    module Resource
      class RegionalFetcherWorker
        include Sidekiq::Worker
        sidekiq_options queue: :gcp_sync, :retry => false, backtrace: true

        def perform(klass, adapter_id, region_id, enabled_region_map, **args)
          CSLogger.info "Step 6 GCP Regional Fetcher Worker Started | Klass - #{klass} | adp_id - #{adapter_id} | region_id  - #{region_id}"
          adapter = Adapter.find_by(id: adapter_id)
          region = Region.find_by(id: region_id)
          CSLogger.info "Step 6 again Regional Fetcher Worker with names | class - #{klass} | adp_id - #{adapter_id} | adapter_name - #{adapter.name} | region_name - #{region.region_name}"
          return if adapter.blank? || region.blank?

          klass.constantize.sync_regional(adapter, enabled_region_map, region)
        rescue StandardError => e
          CSLogger.error "ISSUE HERE Step 6 Sync::GCP::Resource::RegionalFetcherWorker | Error - #{e.message} | adp_id - #{adapter_id} | region_id  - #{region_id}"
          CSLogger.error e.backtrace
        end
      end
    end
  end
end
  