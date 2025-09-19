# frozen_string_literal: true

module Azure
  # Worket to initiate deletion process
  # of azure's 30+ days older resource
  class AccountWiseResourceCleaner
    include Sidekiq::Worker
    sidekiq_options queue: :azure_idle_queue, backtrace: true

    def perform(account_id)
      account = Account.find_by(id: account_id)
      return unless account.present?

      CSLogger.info "============ Started cleaning 30 days older deleted azure resources of account : #{account.try(:name)}"
      account_adapters = account.adapters.azure_adapter.normal_adapters.includes(:resource_groups)
      options = { account_id: account_id }
      resource_cleaner_batch = Sidekiq::BatchCreator.call(Azure::AzureResourceCleanerCallback,
                                                          options,
                                                          'Clean Azure resources older than 30 days')
      resource_cleaner_batch.jobs do
        account_adapters.each do |adapter|
          adapter.resource_groups.each do |resource_group|
            Azure::DeletedResourceCleaner.perform_async(resource_group.id, adapter.id)
          end
        end
      end
    end
  end

  # Callback class for Azure resoruce cleaner
  class AzureResourceCleanerCallback
    def on_complete(_status, _options) end

    def on_success(_status, options)
      account = Account.find_by(id: options['account_id'])
      CSLogger.info "Cleanup process completed for account --  #{account.name}"
    end
  end
end
