=begin
Class that updates adapters from budgets of child organisation, 
when parent organisation unshares normal adapters which was present in child org's budgets
=end

class ChildOrganisation::RemoveAdaptersFromBudgets
  include Sidekiq::Worker
  sidekiq_options queue: :api, backtrace: true

  def perform(adapter_ids_to_remove, removed_adapter_group_ids, child_organisation_id, user_id)
    CSLogger.info "=========================In RemoveAdaptersFromBudgets=================="
    user = User.find_by(id: user_id)
    child_organisation = Organisation.find_by(id: child_organisation_id)
    return unless child_organisation.present?

    child_organisations = [child_organisation]
    child_organisations << child_organisation.child_organisations
    child_organisations.flatten!
    child_organisations.each do |child_org|
      child_org.tenants.each do |tenant|
        TenantUpdateBudgetWorker.perform_async(adapter_ids_to_remove, removed_adapter_group_ids, user_id, tenant.id)
      end
    end
  end
end
