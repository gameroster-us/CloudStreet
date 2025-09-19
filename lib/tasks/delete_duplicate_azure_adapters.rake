namespace :delete_duplicate_azure_adapters do
  task destroy_not_configured: :environment do
    
    org = Organisation.find_by(subdomain: "spriha")
    if org.nil?
      CSLogger.info "Organisation not found"
      next
    end
    all_adapters = [] 
    azure_adapters = org.account.adapters.azure_adapter.normal_adapters.not_configured
    result = azure_adapters.group("data -> 'subscription_id'").count
    result.each do |subscription_id, count|
      adapters_to_delete = []
      next if count < 2

      dup_adapters = azure_adapters.where("data -> 'subscription_id' =?", subscription_id)
      CSLogger.info "Duplicates adapters count #{count} for subscription_id #{subscription_id}"
      adapters_to_delete << dup_adapters.last(count - 1).pluck(:id)
      adapters_to_delete = adapters_to_delete.flatten
      CSLogger.info "Adapter ids to delete from subdomain #{org.subdomain} : #{adapters_to_delete}"
      CSLogger.info "Number of adapter ids to delete: #{adapters_to_delete.count}"
      #deleting adapters
      ActiveRecord::Base.transaction do
        OrganisationAdapter.where(adapter_id: adapters_to_delete).destroy_all
        TenantAdapter.where(adapter_id: adapters_to_delete).destroy_all
        Adapter.where(id: adapters_to_delete).destroy_all
        all_adapters << adapters_to_delete
      end
    end
    CSLogger.info "All adapters deleted: #{all_adapters}"
  end
end

