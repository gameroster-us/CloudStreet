class ServiceAdviserSummaryDataSaverWorker

  include Sidekiq::Worker
  sidekiq_options queue: :service_adviser_summary, retry: false, backtrace: true
  def perform(account_id, tenant_id=nil, options = {}, synchronization_id=nil)
  CSLogger.info "******* In ServiceAdviserSummaryDataSaverWorker Started | Account ID: #{account_id} | Tenant Id: #{tenant_id} | options: #{options} *******"
    account = Account.find(account_id)
    organisation = account.organisation
    if tenant_id
      CurrentAccount.account = account
      tenant = Tenant.find(tenant_id)
      ServiceAdviser::Base.get_dashboard_summary(account, tenant, nil, false, false, options)
      FetchStoreRISpPotentialBenefitTenantWiseService.new(account, tenant).call if options.has_key?('run_ri_sp') && options['run_ri_sp'].eql?(true)
      ServiceGroups::UpdateCostTenantWise.perform_async({ account_id: account.id, tenant_id: tenant.id }) if options.has_key?('run_service_group') && options['run_service_group'].eql?(true)
    else
      update_tenant_level_summary(organisation, options)

      # Upating child organisations summary
      if organisation.parent_id.nil? || organisation.organisation_purpose.eql?('reseller')
        child_organisations = Organisation.where(id: organisation.child_organisations_ids_from_every_level)

        child_organisations.each do |org|
          update_tenant_level_summary(org, options)
        end
      end
    end
    # synchronization_id not nil means it is came from synchronization
    unless synchronization_id.nil?
      synchronizer = ServiceSynchronizer.new(account_id)
      synchronizer.alert_service_adviser_dashbard_complete(synchronization_id)
    end
    CSLogger.info "******* In ServiceAdviserSummaryDataSaverWorker Completed | Account ID: #{account_id} | Tenant Id: #{tenant_id} | options: #{options} *******"
  rescue Exception => e
    CSLogger.error e.backtrace.to_s
    CSLogger.error "===== oh no Exception in ServiceAdviserSummaryDataSaverWorker | Account ID: #{account_id} | Tenant Id: #{tenant_id} | options: #{options} | ERROR =====> #{e.message}"
    raise e
  end

  def update_tenant_level_summary(organisation, options = {})
    CurrentAccount.account = organisation.account
    from_delete_worker = options['from_delete_worker'] # For delete we are updating each tenant service adviser data.
    organisation.tenants.each do |tenant|
      # Skipping tenant if adapter id is comming in options & the same adapter is not present in the current tenant.
      next if !from_delete_worker && options.key?('adapter_id') && !tenant.adapters.where(id: options['adapter_id']).exists?

      ServiceAdviser::Base.get_dashboard_summary(organisation.account, tenant, nil, false, false, options)
      FetchStoreRISpPotentialBenefitTenantWiseService.new(organisation.account, tenant).call if options.has_key?('run_ri_sp') && options['run_ri_sp'].eql?(true)
      ServiceGroups::UpdateCostTenantWise.perform_async({ account_id: organisation.account.id, tenant_id: tenant.id }) if options.has_key?('run_service_group') && options['run_service_group'].eql?(true)
    end
  end

end
