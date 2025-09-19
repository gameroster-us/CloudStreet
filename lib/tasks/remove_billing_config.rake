# rake sync_adapters:auto_sync

namespace :remove_billing_config do
  desc 'This task is to run auto sync'
  task without_adapter_group: :environment do
    Adapters::AWS.billing_adapters.active_adapters.each do |billing_adapter|
      CurrentAccount.client_db = billing_adapter.account
      BillingConfiguration.where(adapter_id: billing_adapter.id).each do |billing_config|
        if billing_config.adapter_groups.size > 1
          billing_config.adapter_groups.delete_if{|ag| !ServiceGroup.find_by(id: ag["id"]).present? }
          billing_config.save
        else
          id = billing_config.adapter_groups.first["id"] rescue('')
          billing_config_adapter_group = ServiceGroup.find_by(id: id)
          billing_config.destroy unless billing_config_adapter_group.present?
        end
      end
    end
  end
end