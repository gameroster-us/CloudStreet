# frozen_string_literal: true

# GCP updater adapter class
class Adapters::Updaters::GCP < CloudStreetService

  class << self

    def call(user, tenant, adapter, params, &block)
      adapter = assign_params_to_adapter(adapter, params)
      if verify_gcp_account(adapter)
        linked_accounts = []
        is_billing_linked = (adapter.adapter_purpose == 'billing' && adapter.is_gcp_linked_account)
        linked_accounts = AdapterSearcher.check_linked_projects(params[:account_id], adapter) if is_billing_linked
        param_hash = params.slice('account_id')
        param = param_hash.to_h.symbolize_keys
        if adapter.save
          if params[:adapter_purpose].eql?('billing')
            CreateLinkAdaptersWorker.perform_async(adapter.id, param, linked_accounts, tenant.organisation.id, user.id, tenant.id) if linked_accounts.any?
            adapter.gcp_report_configuration.delete if adapter.gcp_report_configuration.present?
            adapter.trigger_report_api(adapter.previous_changes)
          else
            adapter.perform_sync_task
          end
          CloudStreetService.status AdapterStatus, :success, AdapterInfo.new(adapter), &block
        else
          CSLogger.error "Invalid adapter details! :: #{adapter.errors.inspect}"
          CSLogger.info adapter.inspect
          status AdapterStatus, :validation_error, adapter, &block
        end
      else
        adapter.errors[:base] << 'Credentials are invalid.'
        status AdapterStatus, :validation_error, adapter, &block
      end
    end

    private

    def assign_params_to_adapter(adapter, params)
      adapter.assign_attributes({
        name: params[:name],
        adapter_purpose: params[:adapter_purpose],
        state: :active,
        is_billing: (params[:adapter_purpose] == 'billing'),
        gcp_access_keys: (JSON.parse(params[:gcp_access_keys]) rescue {}),
        dataset_id: params[:dataset_id],
        table_name: params[:table_name],
        is_gcp_linked_account: params[:is_linked_account],
        invoice_date: params[:invoice_date],
        enable_invoice_date: params[:enable_invoice_date],
        credentials_error_msg: adapter.credentials_error_msg || '',
        margin_discount_calculation: params[:margin_discount_calculation]
      })
      adapter
    end


    def verify_gcp_account(adapter)
      if adapter.gcp_access_keys.present? || adapter.dataset_id.present? || adapter.table_name.present?
        adapter.validate_credentials?
      else
        true
      end
    end

  end
end
