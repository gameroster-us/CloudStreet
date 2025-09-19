# rake update:tenant_default_tags
namespace :update do
  desc "Update tanant default tags"
  task tenant_default_tags: :environment do
    Tenant.all.each do |tenant|
      tenant.update(tags: {})
      CSLogger.info "Updating default tenant tags for organisation id #{tenant.try(:organisation_id)}"
    end
  end
end
