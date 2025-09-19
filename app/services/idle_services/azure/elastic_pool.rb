# frozen_string_literal: false

module IdleServices
  module Azure
    # Service class to identify idle elastic pool
    class ElasticPool < IdleServices::Azure::AzureMetricFetcher
      class << self
        def compute_idle_service(adapter, monitor_client, resources, updatable_services)
          CSLogger.info "Idle state started of Elastic Pool(s) for adapter : #{adapter.name}"
          account = adapter.account
          resources.each do |resource|
            begin
              next unless resource.type.eql?('Azure::Resource::Database::SQL::ElasticPool')

              if resource.vcore_based_pool?
                elastic_pool_default_config = account.service_adviser_configs.azure_idle_elastic_vcore_default_config
              else
                elastic_pool_default_config = account.service_adviser_configs.azure_idle_elastic_dtu_default_config
              end
              configs = format_idle_configs(elastic_pool_default_config.config_details)
              idle_status = check_idle_status(resource, monitor_client, configs)
              update_idle_service_array(resource, updatable_services, idle_status)
            rescue StandardError => e
              CSLogger.error "Something went wrong inside IdleServices::Azure::ElasticPool -- Error: #{e.message}"
              CSLogger.error e.backtrace
            end
          end
        end
      end
    end
  end
end
