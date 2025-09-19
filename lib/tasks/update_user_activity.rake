# rake user_activity:update_user_activity
# rake user_activity:update_default_tenant_id_in_user_activity
# rake user_activity:update_adapter_name_in_user_activity

namespace :user_activity do
  desc 'Updating user activity'
  task update_user_activity: :environment do
    CSLogger.info 'Started updating user activity'
    UserActivityWorker.perform_async
    CSLogger.info 'Completed updating user activity'
  end

  desc 'Task to update organisation default tenant id in existing user activity records.'
  task update_default_tenant_id_in_user_activity: :environment do
    Account.find_each do |account|
      default_tenant = account.organisation.get_default_tenant
      next if default_tenant.blank?
      UserActivity.where(account_id: account.id).update_all(tenant_id: default_tenant.id)
      CSLogger.info "Updated default tenant id for account #{account.id}===#{account.try(:name)} in user activity"
    end
  end

  desc 'Task to add adapter name in data attribute in existing user activity records.'
  task update_adapter_name_in_user_activity: :environment do
    UserActivity.where(controller: 'report_data_reprocessings').each do |user_res|
      adapter = Adapter.find_by(id: user_res.data[:adapter_id])
      if adapter.present?
        user_res.data = user_res.data.merge(adapter_name: adapter.name)
      else
        user_res.data = user_res.data.merge(adapter_name: 'NA')
      end
      user_res.save
    end
    CSLogger.info 'Updated adapter name in user activity'
  end

end
