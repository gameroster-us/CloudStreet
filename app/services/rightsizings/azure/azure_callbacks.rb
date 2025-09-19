# frozen_string_literal: true

module Rightsizings
  module Azure 
    module AzureCallbacks
      # callback for azure metric fetrcher
      class RightSizingCloudwatch
        def on_success(_status, _options = {}); end

        def on_complete(_status, options = {})
          CSLogger.info '***********fetched cloudwatch metric data sucessfully***********'
          CSLogger.info '======================= started analyse metric data for right sizing ==============='
          uniq_accounts = Adapters::Azure.where("data->'subscription_id' IN (?)", options['subscription_ids'])
                          .azure_normal_active_adapters
                          .azure_global_cloud_adapters
                          .for_active_accounts
                          .order('created_at')
                          .group_by { |adapter| [adapter.subscription_id, adapter.account_id] }
          callback_options = { 'subscription_ids' => options['subscription_ids'] }
          analyzing_batch  = Sidekiq::BatchCreator.call(AzureCallbacks::VmRightsizingAnalyzingCallback,
                                                        callback_options,
                                                        'Analyse VM metric and find rightsize')
          analyzing_batch.jobs do
            uniq_accounts.each_pair do |(subscription_id, account_id), acc_adapters|
              options = {
                subscription_id: subscription_id,
                account_id: account_id,
                is_csp_subscription: acc_adapters.any?(&:csp_adapter?)
              }
              Azure::Rightsizing::VirtualMachine::AnalyzingWorker.perform_async(options)
            end
          end
        rescue StandardError => e
          CSLogger.error 'something went wrong while analysing vm for rightsizing'
          CSLogger.error e.message
          CSLogger.error e.backtrace
        end
      end

      # callback class azure pricelist worker
      class VmPriceListCallback
        def on_complete(_status, _options); end

        def on_success(_status, _options)
          CSLogger.info '========== VM SKU and Price fetching done for all subscriptions ============'
        end
      end

      # callback class azure sql db pricelist worker
      class SQLDBPriceListCallback
        def on_complete(_status, _options); end

        def on_success(_status, _options)
          CSLogger.info '========== SQL DB Price fetching done for all subscriptions ============'
        end
      end

      # callback class azure sql db matric worker
      class RightSizingSQLDB
        def on_success(_status, _options = {}); end

        def on_complete(_status, _options = {})
          CSLogger.info '======================= started analyse metric data for right sizing ==============='
          uniq_accounts = Adapters::Azure.azure_normal_active_adapters.azure_global_cloud_adapters.for_active_accounts.order('created_at').group_by(&:subscription_id)
          uniq_accounts.each_pair do |subscription_id, acc_adapters|
            right_size_analyser = Rightsizings::Azure::SQLDBRightSizingAnalyzingService.new(subscription_id: subscription_id, adapters: acc_adapters)
            right_size_analyser.start_right_sizing_analysis_process
          end
          CSLogger.info '***** Rightsizing done for all accounts *****'
          if uniq_accounts.keys.any?
            CSLogger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
            account_ids = Adapters::Azure.where("data->'subscription_id' IN (?)", uniq_accounts.keys).pluck(:account_id).compact.uniq
            account_ids.each do |account_id|
              ServiceAdviserSummaryDataSaverWorker.set(queue: 'rightsizing_azure').perform_async(account_id)
            end
            CSLogger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
          end
        rescue StandardError => e
          CSLogger.error 'something went wrong while analysing sql db for rightsizing'
          CSLogger.error e.message
          CSLogger.error e.backtrace
        end
      end

      class VmRightsizingAnalyzingCallback
        def on_success(_status, options)
          CSLogger.info '============= RightSizing sucess for all accounts ============='
          if options.key?('subscription_ids')
            CSLogger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
            account_ids = Adapters::Azure.where("data->'subscription_id' IN (?)", options['subscription_ids']).pluck(:account_id).compact.uniq
            account_ids.each do |account_id|
              ServiceAdviserSummaryDataSaverWorker.set(queue: 'rightsizing_azure').perform_async(account_id)
            end
            CSLogger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
          end
        end

        def on_complete(_status, _options)
          CSLogger.info '============= VM RightSizing completed for all accounts ============='
        end
      end

      class VmAhubRecommendationCallback
        def on_success(_status, options)
          CSLogger.info '============= Azure VM AHUB Recommendation process success for all accounts ============='
          if options.key?('account_ids') && options['account_ids'].any?
            CSLogger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
            options['account_ids'].each do |account_id|
              ServiceAdviserSummaryDataSaverWorker.set(queue: 'azure_recommendation').perform_async(account_id)
            end
            CSLogger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
          end
        end

        def on_complete(_status, _options)
          CSLogger.info '============= Azure VM AHUB Recommendation process completed for all accounts ============='
        end
      end

      class SQLAhubRecommendationCallback
        def on_success(_status, _options)
          CSLogger.info '============= Azure Sql DB AHUB Recommendation process success for all accounts ============='
        end

        def on_complete(status, options)
          CSLogger.info "Completed for account ids #{options["account_id"]}"
          exclude_account_ids = []
          uniq_account_ids = Adapters::Azure.azure_normal_active_adapters.for_active_accounts.where.not(account_id: options["account_id"]).order('created_at').map(&:account_id).uniq
          exclude_account_ids << options["account_id"]
          exclude_account_ids << uniq_account_ids.first
          account_id = uniq_account_ids.first
          if account_id.present?
            account = Account.find(account_id)
            options["account_id"] = exclude_account_ids.flatten.compact
            options["adapter_ids"] = account.adapters.azure_normal_active_adapters.pluck(:id)
            analyzing_batch  = Sidekiq::BatchCreator.call(AzureCallbacks::SQLAhubRecommendationCallback,
                                                      options, 'Identify eligible AHUB SQL DB and run recommendation logic')
            analyzing_batch.jobs do
              Azure::AhubRecommendation::AccountWiseRecommendationWorker.perform_async(options)
            end
          else
            CSLogger.info "Azure SQL DB AHUB Recommendation process completed for all accounts"
            if options.key?('account_ids') && options['account_ids'].any?
              CSLogger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
              options['account_id'].each do |account_id|
                ServiceAdviserSummaryDataSaverWorker.set(queue: 'azure_recommendation').perform_async(account_id)
              end
              CSLogger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
            end
          end
        end
      end
      
      class ElasticPoolAhubRecommendationCallback
        def on_success(_status, options)
          CSLogger.info '============= Azure Sql Elastic Pool AHUB Recommendation process success for all accounts ============='
          if options.key?('account_ids') && options['account_ids'].any?
            CSLogger.info '---- Calling Summary Adviser Worker for Dashborad in background ----'
            options['account_ids'].each do |account_id|
              ServiceAdviserSummaryDataSaverWorker.set(queue: 'azure_recommendation').perform_async(account_id)
            end
            CSLogger.info '---- Ended Summary Adviser Worker for Dashborad in background ----'
          end
        end

        def on_complete(_status, _options)
          CSLogger.info '============= Azure Sql Elastic Pool AHUB Recommendation process completed for all accounts ============='
        end
      end
    end
  end 
end
