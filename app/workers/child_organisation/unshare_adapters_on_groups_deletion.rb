=begin
 When an adapter group is deleted, if it was shared with child organisations,
 then we will unshare the associated normal adapters from child organisation.
=end
class ChildOrganisation::UnshareAdaptersOnGroupsDeletion
  include Sidekiq::Worker
  sidekiq_options queue: :api, backtrace: true

  def perform(organisation_id, adapters, service_group_id, shared_to_child_org_ids)
    CSLogger.info "==========Updating Organisation adapters after deleting service(adapter) groups======="
    organisation = Organisation.find_by(id: organisation_id)
    return unless organisation.present?

    # child_organisations = organisation.child_organisations
    child_organisations = Organisation.where(id: organisation.child_organisations_ids_from_every_level)

    return unless child_organisations.present?

    child_organisations.each do |child_organisation|
      next unless shared_to_child_org_ids.include?(child_organisation.id)

      billing_adapter_ids_in_shared_groups = child_organisation.service_groups.where.not(id: service_group_id).pluck(:billing_adapter_id)
      normal_adapter_ids_in_shared_groups = ServiceGroup.adapterids_from_adapter_group(child_organisation.service_groups.ids)

      adapters_to_unshare = (adapters["normal_adapters"] - normal_adapter_ids_in_shared_groups)
      
      child_orgs = [child_organisation]
      child_orgs << child_organisation.child_organisations
      child_orgs.flatten!
      child_orgs.each do |org|
        unshare_adapters(adapters_to_unshare, org)
      end

      # This was missing before now added on deletion too.
      account_id = child_organisation.account.id
      summary_worker_options = { 'run_ri_sp' => true, 'run_service_group' => true }
      ServiceAdviserSummaryDataSaverWorker.perform_async(account_id, nil, summary_worker_options)
      ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account_id })

      # TenantAdapter.where(adapter_id: adapters_to_unshare, tenant_id: child_organisation.tenants.ids).destroy_all
      # OrganisationAdapter.where(organisation_id: child_organisation.id, adapter_id: adapters_to_unshare).destroy_all
      # ChildOrganisation::Adapter::Updater.remove_adapters_from_child_groups(adapters_to_unshare, child_organisation)
    end
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end

  # unsharing adapters that were present in deleted adapter group
  def unshare_adapters(adapters_to_unshare, child_organisation)
    TenantAdapter.where(adapter_id: adapters_to_unshare, tenant_id: child_organisation.tenants.ids).destroy_all
    OrganisationAdapter.where(organisation_id: child_organisation.id, adapter_id: adapters_to_unshare).destroy_all
    ChildOrganisation::UnshareAdaptersFromResellBillingConfig.perform_async(child_organisation.id, adapters_to_unshare)
    ChildOrganisation::Adapter::Updater.remove_adapters_from_child_groups(adapters_to_unshare, child_organisation)
  end

end