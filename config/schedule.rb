# frozen_string_literal: true

set :output, 'log/whenever.log'
set :environment, ENV['RAILS_ENV']
# http://stackoverflow.com/questions/9482298/rails-cron-whenever-bundle-command-not-found
env :PATH, ENV['PATH']
env :CUSTOMERIO_SITE_ID, ENV['CUSTOMERIO_SITE_ID']
env :CUSTOMERIO_API_KEY, ENV['CUSTOMERIO_API_KEY']

SET_SECRET = "source /home/cloudstreet/api/script/get_secrets.sh && cd /home/cloudstreet/api && bundle exec"

marketplace = (ENV['SAAS_ENV'] == 'false' || ENV['SAAS_ENV'] == false)

every 2.weeks do 
  command "#{SET_SECRET} rake template_costs:fetch_aws_costs" 
end
# for AMI
every 30.minutes do 
  command "#{SET_SECRET} rake organisation_image:archive" 
end

every :day, at: '12:00pm' do
  command "#{SET_SECRET} bin/rails runner CloudTrail::SyncNotificationWorker.perform_async"
end

every :day, at: '12:00pm' do
  command "#{SET_SECRET} rake aws:check_adapter_region_enabled"
end

# To Update EC2 instances cost by hour and save EC2 platform after report data process.
every :day, at: '01:30am' do
  command "#{SET_SECRET} rake aws:ec2_cost_updater"
end

every :day, at: '09:00pm' do
  command "#{SET_SECRET} bin/rails runner ComplianceReportService.store_compliance_chart_data"
end

every :day, at: '10:00am' do
  command "#{SET_SECRET} bin/rails runner Azure::ComplianceReportService.store_compliance_chart_data"
end

every :day, at: '12:15pm' do
  command "#{SET_SECRET} rake chart_history:reset"
end

every 12.hours do
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_cwl"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_trail"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_org"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_iam_certificate"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_config"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_iam_role"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_iam_user"
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_aws_account"
end

every 12.hours do
  command "#{SET_SECRET} rake update_failed_tasks:update_and_notify"
end

case @environment
when 'production'
  every :day, at: '11:30pm' do
    command "#{SET_SECRET} rake es_daily_reports:fetch_schedule"
  end
end

every 4.hours do
  command "#{SET_SECRET} rake azure_security_scan_storer:store_data"
end

if !@environment.eql?('development')
  every 2.hours do
    command "#{SET_SECRET} rake vm_ware_sync:start"
  end
end

# It will run on 02:30 PM
# Idle service worker not run by cloudtrail thats why we are running in a day.
every :day, at: '08:30am' do
  command "#{SET_SECRET} bin/rails runner DailyIdleServiceScheduler.call_idle_worker"
  command "#{SET_SECRET} bin/rails runner DailyLegacyInstanceSizingScheduler.call_legacy_instance_sizing_worker"
end

every :day, at: '12:20am' do
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_policy"
end

every :day, at: '01:00am' do
  command "#{SET_SECRET} rake vm_ware_cost_report:generate"
end

every :day, at: '12:20pm' do
  command "#{SET_SECRET} rake security_data_sync:security_data_sync_for_policy"
end

every 3.hours do
  command "#{SET_SECRET} rake cloud_trail_event:execute_trail, output: log/whenever-cloud-trail.log"
end

every :day, at: '11:45pm' do
  command "#{SET_SECRET} rake cloud_trail_event:clear_cloud_trail_data"
end

every :week, at: '11:30pm' do
  command "#{SET_SECRET} rake cloud_trail_event:clear_cloud_trail_log_data"
end

every :day, at: '6:00pm' do
  # run Azure auto sync
  command "#{SET_SECRET} rake sync_adapters:auto_sync_azure"
end

every :day, at: '7:00pm' do
  command "#{SET_SECRET} rake sync_adapters:auto_sync_gcp"
end

every :day, at: '10:00pm' do
  command "#{SET_SECRET} rake sync_adapters:auto_sync_aws"
end

# At 12:00 PM, on the first Saturday of the month
every '00 12 ? 1/1 SAT#1' do
  command "#{SET_SECRET} rake sync_adapters:auto_sync_all_aws_adapters"
end

every :day, at: '4:30am' do
  command "#{SET_SECRET} rake s3_rightsizing:FetchS3ForRightSizing, output: log/s3-rightsizing.log"
end

every 1.month, :at => '8:15am' do
  command "#{SET_SECRET} rake rds_rightsizing:FetchRDSPriceList, output: log/rds-rightsizing.log"
end

every :day, :at => '8:45am' do
  command "#{SET_SECRET} rake rds_rightsizing:FetchCloudWatchMetricData, output: log/rds-rightsizing.log"
end

every 1.month '5:30am' do
  command "#{SET_SECRET} rake gcp:FetchComputePriceList"
end

case @environment
when 'production'
  every :day, at: '12:20am' do
    command "#{SET_SECRET} rake ec2_rightsizing:fetch_cloudwatch_metric_data"
  end

  every :day, at: ['9:30 am', '9:30 pm'] do
    command "#{SET_SECRET} rake vmware_metrics_csv_to_parquet:process['daily']"
  end

  every '0 6 8 * *' do
    command "#{SET_SECRET} rake gcp:joined_date"
  end
else
  # every 1.week, at: '12:20am' do
  #   rake 'ec2_rightsizing:fetch_cloudwatch_metric_data'
  # end

  every :day, at: ['9:30 pm'] do
    command "#{SET_SECRET} rake vmware_metrics_csv_to_parquet:process['daily']"
  end
end

# every :day, :at => '02:00am' do
#   rake 'cleanup_snapshots:delete_old_snapshots'
# end

if marketplace
  every :day, at: '12:20am' do
    command "#{SET_SECRET} rake backup:dynamo"
  end

  every :day, at: '12:30am' do
    command "#{SET_SECRET} rake scheduler:update"
  end

  every 1.hour do
    command "#{SET_SECRET} rake iam_adapters:synchronize"
  end

else
  # every :day, at: '1:00am' do
  #   runner 'Organisation.send_weekly_summary_to_admin'
  # end

  # every :day, :at => '01:00am' do
  #   runner "Organisation.generate_invoices_cron"
  # end

  # every :day, :at => '03:00am' do
  #   runner "Invoice.pay_invoice_bills"
  # end

  # every 1.day, :at => '12:05am' do
  #   rake "followup_task:start"
  # end

  every :sunday, at: '1:00am' do
    command '/home/cloudstreet/api/script/log_backup.sh'
  end

  # every 1.hour do
  #   runner 'AWSMarketplaceSaasSubscription::BatchMeterUsageWorker.perform_async'
  # end

  every 30.minutes do
    command "#{SET_SECRET} bin/rails runner AWSMarketplaceSaasSubscription::NotificationPollingWorker.perform_async"
  end

  every :day, at: '04:30am' do
    command "#{SET_SECRET} rake adapters:create_linked_adapter"
  end

  every :day, at: '09:30am' do
    command "#{SET_SECRET} rake adapters:create_azure_linked_adapter"
  end

  every 5.minute do
    command "#{SET_SECRET} bin/rails runner SidekiqStatusMonitor.set_cloud_watch_matric_queue_jobs"
  end

  every 5.minute do
    command "#{SET_SECRET} bin/rails runner SidekiqStatusMonitor.set_cloud_watch_matric_busy_jobs"
  end

  every :day, at: '01:00am' do
    # fetch cloudwatch matric data and store maximum usage in table
    command "#{SET_SECRET} rake cloud_watch:fetch_cloud_watch_data_iops"
  end

  # every :day, :at => '12:01am' do
  #   # run auto sync
  #   # rake 'sync_adapters:auto_sync'
  # end

end

# Fetch pricelist for Azure VM Sku for rightsizing : 9:30 AM IST
every :week, at: '4:00am' do
  command "#{SET_SECRET} rake store_azure_vm_sku_pricelist:store"
end

# Run Azure VM rightsizing : 8:30 PM IST
every :day, at: '3:00pm' do
  command "#{SET_SECRET} rake vm_azure_rightsizing:fetch_cloudwatch_metric_data"
end

#Fetch sql db pricelist and store : 3:00 PM IST
every :week, at: '9:30am' do
  command "#{SET_SECRET} rake store_azure_sql_db_sku_pricelist:store"
end


#Fetch metric and perform rightsizing : 3:00 AM IST
every :day, at: '9:30pm' do
  command "#{SET_SECRET} rake sql_db_azure_rightsizing:fetch_sql_db_metric_data"
end

# Store Azure retail price to add missing
# Azure resource cost
every 1.month, at: '11:00pm' do
  command "#{SET_SECRET} rake azure_retail_price_storer:store_retail_price"
end

# Clean Azure deleted resource which are older than 30 days
# Every night 8.30pm UTC / 2.00am IST
every :week, at: '08.30pm' do
  command "#{SET_SECRET} rake clean_azure_deleted_resources:clean"
end

#Update currency Converter latest rates 
every :day, at: '02:00am' do
  command "#{SET_SECRET} rake currency_conversion:store"
end

# Azure AHUB Recommendation(VM)
# AT 10:00 am IST
every :day, at: '4:30am' do
 command "#{SET_SECRET} rake azure_ahub_recommendation:virtual_machine"
end

# Azure AHUB Recommendation(SQL DB)
# AT 2:00 pm IST
every :day, at: '8:30am' do
 command "#{SET_SECRET} rake azure_ahub_recommendation:sql_db"
end

# Azure AHUB Recommendation(SQL DB)
# AT 4:00 pm IST
every :day, at: '11:30am' do
 command "#{SET_SECRET} rake azure_ahub_recommendation:elastic_pool"
end

# this is for creating group for only cirion for specific adapter and tenant HARD CODED
# commenting this rake task as we have added policy based auto group creation schedule daily
# for all accounts
# every :day, at: '12:00am' do
#   rake 'create_group:for_cirion'
# end

# This rake task is responsible for cleaning up ICEBERG manifest file and recreate Athena group tables for all the providers periodically
# Running this task every day

every :day, at: '3:00am' do
  command "#{SET_SECRET} rake group_table_athena:create_table"
end

# This rake task is responsible for cleaning up ICEBERG manifest file.
# And recreate Athena group tables for all the providers of Cirion account
# Running this task every sunday
every :sunday, at: '12:00am' do
  command "#{SET_SECRET} rake group_table_athena:create_table_for_cirion"
end

# Policy based automatic group creator rake task
# Every day except sunday
every [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday], at: '12:00am' do
  command "#{SET_SECRET} rake auto_group_creator:run[AWS]"
  command "#{SET_SECRET} rake auto_group_creator:run[AzureCsp]"
  command "#{SET_SECRET} rake auto_group_creator:run[GCP]"
end

every :day, at: '6:15am' do
  command "#{SET_SECRET} rake auto_assing_recommendation_task:create_tasks"
end

# Send honeybudger notification when athena table not present for organisation 
every 12.hours do
  command "#{SET_SECRET} rake athena_group_table_check:check_presence"
end

# 8:30 AM IST
every :day, at: '03:00am' do
  command "#{SET_SECRET} rake snapshot_glue_cost_updater:update_cost"
end

# Worker for sync account group in this policy not created
#every [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday], at: '3:00am' do
#  command "#{SET_SECRET} rake group_table_athena:execute_for_non_policy_account"
#end

# Worker to update csp customer subscription in group
every :day, at: '04:00am' do
  command "#{SET_SECRET} rake azure_csp_group_subscription:update"
end

# IST to 5:00 AM
# worker to dump Ri Sp Potential Benefit
every :day, at: '11:30pm' do
  command "#{SET_SECRET} rake dump_ri_sp:ri_sp_potential_benefit"
end

# IST to 7:00 AM
# Worker to fetch Ri Sp Potential Benefit
every :day, at: '01:30am' do
  command "#{SET_SECRET} rake fetch_and_store:ri_sp_potential_benefit"
end

# Worker to update service group costing
every :day, at: '04:30pm' do
  command "#{SET_SECRET} rake fetch_service_groups:all_service_groups_cost_updating"
end
