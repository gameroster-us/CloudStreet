class AdapterDeleter < CloudStreetService

  def self.delete(account, adapter, user, &block)
    adapter = fetch Adapter, adapter
    begin
      if !adapter.sync_running 
        if adapter.delete_associated_data(account)
          if adapter.try(:adapter_purpose) == 'billing'
            adapter.account.organisation.tenants.each do |tenant|
              next unless tenant.adapters.include?(adapter)

              tenant.update_tenant_billing_adapter_id(adapter)
            end
          end
          status Status, :success, nil, &block
        else
          status Status, :validation_error, "Unable to delete adapter.", &block
        end
      else
        status Status, :error, "Unable to delete adapter, Sync is in Process", &block
      end
    rescue ActiveRecord::InvalidForeignKey => e
      status Status, :error, "Unable to delete adapter, Sync is in Process", &block
    end
  end

  def self.delete_sub_report_config(report_config_id, &block)
    begin
      report_config = ReportConfiguration.find_by(id: report_config_id)
      if report_config
        report_config.destroy
        status Status, :success, nil, &block
      else
        CloudStreet.log "No configuration found with id = #{report_config_id}"
        status Status, :not_found, nil, &block
      end
    rescue StandardError => e
      CloudStreet.log "Error in deleting config = #{e.message}"
      CloudStreet.log e.backtrace
      Honeybadger.notify(e, error_class: 'AWSReportConfig::DeleteConfig', error_message: "Error in deleting config = #{e.message}", parameters: { report_config_id: report_config_id }) if ENV['HONEYBADGER_API_KEY']
      status Status, :error, nil, &block
    end
  end

  def self.destroy_all(account, type, &block)
    @adapters = account.adapters.where.not(state: 'deleting').where(type: type)
    @adapters.each do |adapter|
      adapter.delete_associated_data(account)
    end
    status Status, :success, nil, &block
  rescue StandardError => e
    CSLogger.error "Error in destroy all adapters = #{e.message}"
    CSLogger.error e.backtrace
    status Status, :error, nil, &block
  end
end
