# frozen_string_literal: true
# worker to fetch SQL DB metrics for right sizing
class AzureFetchSQLDBMetricWorker
  include Sidekiq::Worker
  require_relative '../services/rightsizings/azure/azure_callbacks.rb'
  sidekiq_options queue: :rightsizing_azure, retry: false, backtrace: true

  def perform
    CSLogger.info 'Started fetching sql db matric'
    begin
      uniq_accounts = Adapters::Azure
                      .azure_normal_active_adapters
                      .for_active_accounts.order('created_at')
                      .group_by(&:subscription_id)
      uniq_accounts.reject! { |key, _value| key.blank? }
      unless uniq_accounts.blank?
        callback_options = { 'subscription_ids' => uniq_accounts.keys }
        batch = Sidekiq::Batch.new
        batch.description = 'Batch for fetch sql db metrics'
        batch.on(:success, AzureCallbacks::RightSizingSQLDB, callback_options)
        batch.on(:complete, AzureCallbacks::RightSizingSQLDB, callback_options)
        batch.jobs do
          uniq_accounts.each_pair do |subscription_id, acc_adapters|
            adapter_id = acc_adapters.find(&:verify_connections?).try(:id)
            next if subscription_id.blank? || adapter_id.blank?

            AzureRightSizingSQLDBWorker.perform_async(subscription_id, adapter_id)
          end
        end
      end
    rescue StandardError => e
      CSLogger.error "Exception while fetching metrices for Sql Db #{e}"
    end
    CSLogger.info 'Completed fetching metrices for Sql Db.......'
  end
end
