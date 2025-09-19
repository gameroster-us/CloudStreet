# frozen_string_literal: true

require 'csv'
# worker to fetch and store azure monitor metric data
class AzureRightSizingCloudwatchWorker
  include Sidekiq::Worker
  sidekiq_options queue: :rightsizing_azure, retry: true, backtrace: true

  def perform(subscription_id, adapter_id)
    fetch_cloudwatch_metrics(subscription_id, adapter_id)
  end

  def fetch_cloudwatch_metrics(subscription_id, adapter_id)
    Azure::Metric.vm.where(subscription_id: subscription_id).delete_all
    adapter = Adapter.find_by(id: adapter_id)
    Region::AZURE_MAP.keys.each do |region|
      next if region.blank? || region.eql?('global')

      rc = Rightsizings::Azure::AzureCloudwatchMetricFetcherService.new(subscription: subscription_id,
                                                                        adapter: adapter,
                                                                        region: region)
      rc.fetch_cloudwatch_metrics
    end
    CSLogger.info "********Completed cloudwatch for account--->#{subscription_id}*******"
  rescue StandardError => e
    CSLogger.error "Exception #{e.message}"
  end
end
