require "./lib/node_manager.rb"
module FilerVolumes
  module CloudResources
    module NetAppWorkers
      class VolumesFetcherWorker
        include Sidekiq::Worker
        sidekiq_options queue: :net_app, :retry => 10

        sidekiq_retry_in do |count|
          5
        end

        def perform(filer_id, options)
          CSLogger.info "------- In  FilerVolumes::CloudResources::NetAppWorker"
          filer = Filers::CloudResources::NetApp.find(filer_id)

          FilerVolumes::CloudResources::NetAppService.synchronize_and_save_volumes(filer, options)
          CSLogger.info "Successfully ran FilerVolumes::CloudResources::NetAppWorker"

          rescue => exception
            CSLogger.error "#{exception.backtrace}"
            raise exception
        end
      end
    end
  end
end
