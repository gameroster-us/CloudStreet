# frozen_string_literal: false

namespace :one_time do
  desc 'Create account wise service manager summary tenant wise'
  task create_service_manager_summary: :environment do
    Account.all.find_in_batches(batch_size: 10) do |account_batches|
      account_batches.each do |account|
        next if ServiceManagerSummary.where(account_id: account.id).exists?
 
        ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account.id })
        CSLogger.info "====== created service manager summary for | Account ID: #{account.id} ========"
      end
    end
  end

  desc 'Update account wise service manager & service adviser summary tenant wise'
  task update_service_manager_and_service_adviser_summary: :environment do
    Account.active.find_in_batches(batch_size: 10) do |account_batches|
      account_batches.each do |account|

        ServiceAdviserSummaryDataSaverWorker.perform_async(account.id)
        ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account.id })
        CSLogger.info "====== Updated service manager & service adviser summary for | Account ID: #{account.id} ========"
      end
    end
  end

  desc 'Update account wise service manager & service adviser summary tenant wise with ri sp data'
  task update_service_manager_and_service_adviser_summary_with_ri_sp: :environment do
    Account.active.find_in_batches(batch_size: 10) do |account_batches|
      account_batches.each do |account|

        summary_worker_options = { 'run_ri_sp' => true, 'run_service_group' => true }
        ServiceAdviserSummaryDataSaverWorker.perform_async(account.id, nil, summary_worker_options)
        ServiceManagerSummaryDataSaverWorker.perform_async({ "account_id" => account.id })
        CSLogger.info "====== Updated service manager & service adviser summary for | Account ID: #{account.id} ========"
      end
    end
  end

  desc 'create index on mongo table cost by day'
  task create_index_on_cost_by_day: :environment do
    Organisation.all.each do |org|
      CurrentAccount.client_db = org.account
      CostByDay.create_indexes
    end
  end
  
  desc 'create_default_service_group_cost_data'
  task create_default_service_group_cost_data: :environment do
    Organisation.all.each do |organisation|
      account = organisation.account
      tenants = organisation.tenants
      tenants.each do |tenant|
        tenant_ids = tenant.is_default ? organisation.tenants.pluck(:id) : tenant.id
        all_service_groups = (ServiceGroup.where(tenant_id: tenant_ids, account_id: account.id) + tenant.service_groups)
        all_service_groups.each do |service_group|
          sg = ServiceGroupCost.find_or_initialize_by(tenant_id: tenant.id, service_group_id: service_group.id)
          sg.service_group_name = service_group.name
          sg.provider_type = service_group.provider_type
          sg.save
        end
      end
    end
  end

  desc 'updating ram size value for aws server'
  task adding_ec2_ram_size: :environment do
    UpdatingServerRamSizeWorker.perform_async  
  end

end