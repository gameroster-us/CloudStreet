require "./lib/node_manager.rb"
module FilerVolumes
  module CloudResources
    module NetAppWorkers
      class VolumeCreatorWorker
        include Sidekiq::Worker
        sidekiq_options queue: :net_app, :retry => 10

        sidekiq_retry_in do |count|
          5
        end

        def perform(params)
          CSLogger.info "------- In  FilerVolumes::CloudResources::NetAppWorker::VolumeCreatorWorker"
          FilerVolumes::CloudResources::NetAppService.create(params)
          CSLogger.info "Successfully ran FilerVolumes::CloudResources::NetAppWorker::VolumeCreatorWorker"
        rescue => exception
          CSLogger.error "#{exception.backtrace}"
          raise exception
        end
      end
    end
  end
end
