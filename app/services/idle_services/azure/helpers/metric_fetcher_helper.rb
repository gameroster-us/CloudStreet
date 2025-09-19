# frozen_string_literal: true

module IdleServices
  module Azure
    # module contains helper method for azure metric fetching
    module Helpers
      # metric fetcher helper
      module MetricFetcherHelper
        def fetch_metric(resource, monitor_client, options)
          monitor_data = monitor_client.list(resource.provider_data['id'], options)
          monitor_data.on_success { |result| return result }

          monitor_data.on_error do |_error_code, error_message, _data|
            CSLogger.error error_message
            nil
          end
        rescue StandardError => e
          CSLogger.error "==== Something went wrong while fetching azure metric | Adapter: #{resource.adapter.name} Resource: #{resource.name} ======"
          CSLogger.error "=== Error : #{e.message} ==="
        end

        def update_resource_table(updatable_services, service_klass)
          service_klass.constantize.import(updatable_services,
                                           on_duplicate_key_update: {
                                             conflict_target: [:id],
                                             columns: %i[idle_instance]
                                           })
        end
      end
    end
  end
end
