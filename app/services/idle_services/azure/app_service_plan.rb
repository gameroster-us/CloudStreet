# frozen_string_literal: false

# IdleServices::Azure::AppServicePlan.compute_idle_service(adapter, resources, service_Klass='', data='')

module IdleServices
  module Azure

    # class to check idle condition for Azure App Service Plan
    class AppServicePlan < IdleServices::Azure::AzureMetricFetcher
      # extend IdleServices::Azure::Helpers::MetricFetcherHelper

      # The threshold limit is tier specific for each metric.
      # We will use the threshold value from this constant
      # to check idle_status of a app service plan tier
      # threshold_value = THRESHOLD_LIMITS.dig(metric_name.to_sym, plan_tier)
      THRESHOLD_LIMITS = {
        CpuPercentage: {

        },
        MemoryPercentage: {

        }
      }.freeze

      class << self
        def compute_idle_service(adapter, resources, service_klass = '', _data = '')
          CSLogger.info "Idle state started of App Service Plan(s) for adapter : #{adapter.name}"
          updatable_services = []
          monitor_client = adapter.azure_monitor(adapter.subscription_id)
          account = adapter.account
          app_service_plan_default_config = account.service_adviser_configs.azure_idle_app_service_plan_default_config
          configs = format_idle_configs(app_service_plan_default_config.config_details)

          begin
            resources.each do |resource|
              idle_status = check_idle_status(resource, monitor_client, configs)
              update_idle_service_array(resource, updatable_services, idle_status)
            end
          rescue Adapters::InvalidAdapterError => _e
            CSLogger.error 'Inside IdleServices::Azure::AKS -- Invalid adapter credentials or permission for Adapter'
            CSLogger.error e.backtrace
          rescue StandardError => e
            CSLogger.error "Something went wrong inside IdleServices::Azure::AppServicePlan -- Error: #{e.message}"
            CSLogger.error e.backtrace
          end
          ::Azure::Resource::Web::AppServicePlan.import updatable_services, on_duplicate_key_update: { conflict_target: [:id], columns: %i[idle_instance] }
          # update_resource_table(updatable_services, service_klass)
          CSLogger.info "Idle state updated of #{updatable_services.length} App Service Plan(s) for adapter : #{adapter.name}"
        end
      end
    end
  end
end
