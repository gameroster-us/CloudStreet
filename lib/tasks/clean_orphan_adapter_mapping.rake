# frozen_string_literal: true

namespace :orphan_adapter_mapping do
  desc 'task to clean the orphan adapter mapping records'
  # Example usage:
  #   rake orphan_adapter_mapping:clean[azure]
  task :clean, [:service_provider] => [:environment] do |_task, args|
    provider = args[:service_provider].try(:downcase)
    if %w[azure aws gcp].include?(provider)

      adapter_mappings = {
        aws: { mapping_class: 'AWSAccountIds', adapter_class: 'Adapters::AWS' },
        gcp: { mapping_class: 'GCPAccountIds', adapter_class: 'Adapters::GCP' },
        azure: { mapping_class: 'AzureAccountIds', adapter_class: 'Adapters::Azure' }
      }.freeze

      mapping_class = adapter_mappings[provider.to_sym][:mapping_class].constantize
      adapter_class = adapter_mappings[provider.to_sym][:adapter_class].constantize
      CSLogger.info "=== Cleaning orphan #{mapping_class} records ==="
      CSLogger.info "Total account to process : #{Account.count}"
      orphan_adapter_count = 0
      Account.find_each(batch_size: 100).with_index do |account, index|
        CSLogger.info "Processing account(#{account.id}) - #{index}"
        CurrentAccount.client_db = account
        adapter_ids = mapping_class.pluck(:adapter_id)
        existing_adapter_ids = adapter_class.where(id: adapter_ids).pluck(:id)
        orphan_adapter_ids = adapter_ids - existing_adapter_ids
        next if orphan_adapter_ids.blank?

        orphan_adapter_count += orphan_adapter_ids.count
        CSLogger.info "Clearing AzureAccountIds records with adapter ids: #{orphan_adapter_ids} "
        mapping_class.where(:adapter_id.in => orphan_adapter_ids).destroy_all
      end
      CSLogger.info "=== Process finished ; Toal cleaned orphan adapter mapping: #{orphan_adapter_count} ==="
    else
      CSLogger.info "Invalid service provider #{provider}; Process terminated."
    end
  end
end
