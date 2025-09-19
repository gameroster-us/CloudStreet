# frozen_string_literal: true

require_relative "#{Rails.root}/app/services/rightsizings/azure/azure_callbacks.rb"

namespace :store_azure_sql_db_sku_pricelist do
  desc 'Store azure sql db sku with pricelist'
  task store: :environment do
    CSLogger.info '========= started storing azure SQLDB SKU with pricelist =================='
    Adapter.store_sqldb_retail_pricelist
    uniq_subscriptions = Adapters::Azure.normal_adapters.where(state: 'active').group_by(&:subscription_id)
    uniq_subscriptions.keys.reject! { |key, _value| key.blank? }
    options = {}
    pricelist_batch = Sidekiq::BatchCreator.call(AzureCallbacks::SQLDBPriceListCallback,
                                                 options,
                                                 'Fetch and store SQLDB SKU with pricelist')
    pricelist_batch.jobs do
      uniq_subscriptions.each_pair do |subscription, adapters|
        adapter = adapters.find(&:verify_connections?)
        next if adapter.blank?
        Azure::SQLDBPriceListWorker.perform_async(subscription, adapter.id)
      end
    end
  end
end
