# rake vm_azure_rightsizing:fetch_cloudwatch_metric_data
# frozen_string_literal: true

namespace :vm_azure_rightsizing do
  desc 'Task to process virutal machines for azure rightsizing'
  task fetch_cloudwatch_metric_data: :environment do
    CSLogger.info '******* Execution of fetching virutal machines cloudwatch metrices data started in background ********'
    uniq_accounts = Adapters::Azure.azure_normal_active_adapters.for_active_accounts.order('created_at').group_by(&:subscription_id)
    return unless uniq_accounts.present?

    # VmPriceListWorker.perform_async
    AzureFetchCloudwatchMetricsWorker.perform_async
  end
end
