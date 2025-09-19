# frozen_string_literal: true

# GCP Linked accounts creator
class Adapters::LinkedAccount::Creator::GCP < CloudStreetService

  include Adapters::Helpers::Common

  class << self

    def call(options)
      billing_adapter = Adapters::GCP.billing_adapters.find_by(id: options[:adapter_id])
      return unless billing_adapter.present?

      init_gcp_adapter(billing_adapter)
      params = { account_id: options[:account_id] }
      having_linked_accounts = billing_adapter.get_associated_projects
      CSLogger.info "=============================#{having_linked_accounts}============================"
      return unless having_linked_accounts.any?

      CreateLinkAdaptersWorker.perform_async(billing_adapter.id, params, having_linked_accounts, options[:organisation_id], options[:user_id], options[:tenant_id])
    end

    def init_gcp_adapter(adapter)
      gcp_access_keys = JSON.parse(adapter.decrypt_value(adapter.data['auth_keys']))
      adapter.gcp_access_keys = gcp_access_keys
      adapter.dataset_id = gcp_access_keys['dataset_id']
      adapter.table_name = gcp_access_keys['table_name']
    end

  end

end
