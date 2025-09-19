=begin 
When a service adapter group of parent is updated, 
and if the service group is shared with child org, then we update the shared adapters of the child organisation as well.
=end

class ChildOrganisation::UpdateAdaptersInChildOrgWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, backtrace: true

  def perform(organisation_id, adapter_group_id, old_adapter_ids)
    CSLogger.info "==========Updating Organisation adapters afterupdating service groups======="
    organisation = Organisation.find_by(id: organisation_id)
    return unless organisation.present?

    child_organisations = Organisation.where(id: organisation.child_organisations_ids_from_every_level)
    return unless child_organisations.present?

    child_organisations.each do |child_organisation|

      shared_adapter_group = child_organisation.service_groups.find_by(id: adapter_group_id)
      next unless shared_adapter_group.present?

      child_orgs = [child_organisation]
      child_orgs << child_organisation.child_organisations
      child_orgs.flatten!

      shared_normal_adapter_ids = child_organisation.shared_adapters.normal_adapters.ids
      adapter_ids_to_share = ServiceGroup.adapterids_from_adapter_group(adapter_group_id)
      child_org_default_tenant = child_organisation.get_default_tenant
      
      #removing adapters from childs of child
      child_orgs.each do |org|
        update_adapters(org, old_adapter_ids, adapter_ids_to_share)
      end

      #insertion of new adapters
      new_adapters_to_share = adapter_ids_to_share - shared_normal_adapter_ids
      new_adapters = Adapter.where(id: new_adapters_to_share)
      account_id = child_organisation.account.id
      summary_worker_options = { 'run_ri_sp' => true, 'run_service_group' => true }
      # Move code here bcuz before it was calling twice removing and adding on both
      unless new_adapters.present?
        ServiceAdviserSummaryDataSaverWorker.perform_async(account_id, nil, summary_worker_options)
        ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account_id })
        next
      end

      child_organisation.adapters.push(new_adapters)
      options = { tenant_id: child_organisation.tenants.sub_tenants.ids, service_group_id: adapter_group_id }
      tenant_having_shared_groups = TenantServiceGroup.where(options).pluck(:tenant_id)
      tenant_having_shared_groups.each do |tenant_id|
        Tenant.find(tenant_id).original_adapters.push(new_adapters)
      end
      ServiceAdviserSummaryDataSaverWorker.perform_async(account_id, nil, summary_worker_options)
      ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account_id })
      #deletion of old adapters
      # adapter_ids_to_remove = old_adapter_ids - adapter_ids_to_share
      # ChildOrganisation::Adapter::Updater.remove_adapters_from_child_groups(adapter_ids_to_remove, child_organisation)
      # TenantAdapter.where(adapter_id: adapter_ids_to_remove, tenant_id: child_organisation.tenants.ids).destroy_all
      # OrganisationAdapter.where(organisation_id: child_organisation.id, adapter_id: adapter_ids_to_remove).destroy_all
    end
  rescue StandardError => e
    CSLogger.error e.message
    CSLogger.error e.backtrace
  end


  def update_adapters(child_organisation, old_adapter_ids, adapter_ids_to_share)
    #deletion of old adapters
    adapter_ids_to_remove = old_adapter_ids - adapter_ids_to_share
    ChildOrganisation::UnshareAdaptersFromResellBillingConfig.perform_async(child_organisation.id, adapter_ids_to_remove)
    ChildOrganisation::Adapter::Updater.remove_adapters_from_child_groups(adapter_ids_to_remove, child_organisation)
    TenantAdapter.where(adapter_id: adapter_ids_to_remove, tenant_id: child_organisation.tenants.ids).destroy_all
    OrganisationAdapter.where(organisation_id: child_organisation.id, adapter_id: adapter_ids_to_remove).destroy_all
    # account_id = child_organisation.account.id
    # ServiceAdviserSummaryDataSaverWorker.perform_async(account_id)
    # ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account_id })
  end
end
