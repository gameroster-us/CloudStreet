namespace :billing_adapter_assignment_to_group do
  desc "Assign billing adapter to all the groups where billing adapter id is blank/nil"
  task assign_billing_adapter: :environment do
    Account.all.each do |account|
      CurrentAccount.client_db = account
    	service_groups = account.service_groups.where("billing_adapter_id = ? OR provider_type =?", nil, 'Azure')
      # first add billing adapter for adapter group then tag_group and lastly resource_group
      add_billing_adapter(service_groups.adapter_groups)
      add_billing_adapter(service_groups.tag_groups)
      add_billing_adapter(service_groups.resource_groups)
      Thread.current[:client_db] = 'api_default'
    end
  end

  def add_billing_adapter(service_groups)
    service_groups.each do |service_grp|
      begin
        service_grp.add_billing_adapter_to_adapter_group if service_grp.type.eql?('Groups::Adapter')
        service_grp.add_billing_adapter_to_tag_group if service_grp.type.eql?('Groups::Tag')
        service_grp.add_billing_adapter_to_resource_group if service_grp.type.eql?('Groups::Resource')
      rescue Exception => e
        CSLogger.error "===============Error occured while updating billing adapter to #{service_grp.type}============="
        CSLogger.error "account_id: #{service_grp.account_id}, group id: #{service_grp.id}"
        CSLogger.error "error : #{e.message}"
      end
    end
  end
end
