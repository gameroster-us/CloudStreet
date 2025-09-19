require 'factory_bot'

onetime_methods = ['seed_first_deployment_tasks', 'rds_flavour_dump', 'create_currency_converter_base_record']

onetime_rake_tasks = [
  'template_costs:fetch_aws_costs',
  # 'adapters:create_from_iam',
  'update_region:update_account_regions_for_azure',
  'update_region:update_account_regions_for_gcp',
  'update_gcp_multi_region:update_account_multi_regions_for_gcp',
  #'update_region:update_account_regions_for_aws',
  # 'service_hourly_cost:set',
  # 'cost_data:build_dashboard_data',
  # 'snapshot:update_hourly_cost',
  # 'provider_data:update_provider_created_at',
  # 'delete_duplicate:cost_data',
  # 'update_service:created_by',
  # 'access_rights:create',
  # 'access_rights:update_CS_admin',
  # 'azure_ratecard:fetch_ratecards_for_existing_subscriptions',
  'fetch_iam_roles:execute',
  'convert_tasks:convert_tasks_to_auto_sync',
  'time_zones:update_time_zones',
  'default_service_names:add_vpc', # For now added this task here because it not working from seed_first_deployment_tasks
#  'monash:replace_sg["SG-Default-1","SG-Default-2"]'
  'update_task:update_task_type',
  'one_time:create_default_service_group_cost_data',
  'one_time:create_index_on_cost_by_day',
  'one_time:update_service_manager_and_service_adviser_summary_with_ri_sp',
  'access_rights:update_default_roles_access',
  'office365_services:populate_office365_services',
  'one_time:adding_ec2_ram_size',
  'update_org_group_sync_status:update'
]

def deployment_rake_tasks
  ['feature_flags:create']
end

(onetime_methods + onetime_rake_tasks).each do |script_type|
  first_deloyment_status = ScriptRunStatus.find_or_create_by(script_type: script_type) do |script_run_status|
    script_run_status.run_status = false
  end
end

def rds_flavour_dump
  RdsDump.new(nil).store_parsed_data
end

def create_currency_converter_base_record
  base_curr_entry = CurrencyConverter.where(default_currency: true).first
  if base_curr_entry.present?
    base_curr_entry.base = base_curr_entry.base.concat(["ARS", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "HKD", "IDR", "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "RUR", "SAR", "SEK", "TRY", "TWD", "USD", "ZAR"]).uniq
    base_curr_entry.save
    CSLogger.info "Base entry for currency converter allready exist "
  else
   CurrencyConverter.collection.insert_one({base: ["ARS", "AUD", "BRL", "CAD", "CHF", "CNY", "DKK", "EUR", "GBP", "HKD", "IDR", "INR", "JPY", "KRW", "MXN", "MYR", "NOK", "NZD", "RUR", "SAR", "SEK", "TRY", "TWD", "USD", "ZAR"], timestamp: Time.now.to_i, rates: {}, default_currency: true})
  end
end

def seed_first_deployment_tasks

    CSLogger.info "first_deployment_tasks start!"
    ApplicationPlan.find_or_create_by(name: 'viewer', description: 'viewer plan', trial_period_days: 0)
    ApplicationPlan.find_or_create_by(name: 'normal', description: 'normal plan', trial_period_days: 0)

    #methods
    populate_proividers
    create_region_if_not_available
    populate_access_rights
    populate_services
    create_default_storage
    update_synchronization_status_if_running

end

def populate_proividers
  [
    {attribute: :azure, type: 'Adapters::Azure'},
    {attribute: :aws, type: 'Adapters::AWS'},
    {attribute: :vm_ware, type: 'Adapters::VmWare'},
    {attribute: :gcp, type: 'Adapters::GCP'}
  ].each do |provider|
    adapter = Adapter.where(state: 'directory', type: provider[:type]).first
    FactoryBot.create :adapter, :directory, provider[:attribute] unless adapter
  end
end

def create_region_if_not_available
  Adapter.directoried.each do |adapter|
    zone_map = regions_map = multi_regional_map = {}
    case adapter.type
    when 'Adapters::AWS'
      regions_map = Region::MAP
    when "Adapters::Azure"
      regions_map = Region::AZURE_MAP
    when 'Adapters::GCP'
      regions_map = Region::GCP_MAP
      zone_map = GCP::ResourceZone::ZONE_MAP
      multi_regional_map = GCP::MultiRegional::MULTI_REGIONAL_MAP
    end

    regions_map.each do |code, name|
      Region.find_or_create_by(code: code, adapter_id: adapter.id) do |region|
        region.region_name = name
      end
    end

    # This is run only for gcp adapter either zone map will be empty
    zone_map.each do |code, region_code|
      GCP::ResourceZone.find_or_create_by(code: code, adapter_id: adapter.id) do |zone|
        zone.zone_name = code
        region = Region.find_by(code: region_code, adapter_id: adapter.id)
        zone.region_id = region.id if region
      end
    end

    # This is run only for gcp adapter either MULTI REGIONAL MAP  will be empty
    multi_regional_map.each do |code, name|
      GCP::MultiRegional.find_or_create_by(code: code, adapter_id: adapter.id) do |multi_regional|
        multi_regional.name = name
      end
    end
  end
end

def populate_services
  [
    [:service, :directory, :internet, :generic],
    [:service, :directory, :generic_internet_aws],
    [:service, :directory, :internet, :vpc],
    [:service, :directory, :generic_internet_aws, :generic_vpc],
    [:service, :directory, :availability_zone, :generic],
    [:service, :directory, :generic_availability_zone],
    [:service, :directory, :load_balancer, :generic],
    [:service, :directory, :load_balancer, :load_balancer_aws, :aws],
    [:service, :directory, :generic_load_balancer_aws, :aws],
    [:service, :directory, :load_balancer, :load_balancer_rackspace, :rackspace],
    [:service, :directory, :load_balancer_rackspace, :rackspace],
    [:service, :directory, :generic_load_balancer_rackspace, :rackspace],
    [:service, :directory, :application_load_balancer, :aws],
    [:service, :directory, :network_load_balancer, :aws],

    [:service, :directory, :subnet, :generic],
    [:service, :directory, :subnet, :subnet_aws, :aws],
    [:service, :directory, :generic_subnet_aws, :aws],
    [:service, :directory, :subnet, :subnet_rackspace, :rackspace],
    [:service, :directory, :generic_subnet_rackspace, :rackspace],
    [:service, :directory, :subnet, :subnet_azure, :azure],

    [:service, :directory, :server, :generic],
    [:service, :directory, :server, :server_aws, :aws],
    [:service, :directory, :generic_server_aws, :aws],
    [:service, :directory, :server, :server_azure, :azure],
    [:service, :directory, :server, :server_rackspace, :rackspace],
    [:service, :directory, :generic_server_rackspace, :rackspace],

    [:service, :directory, :network_interface, :generic],
    [:service, :directory, :network_interface, :network_interface_aws, :aws],
    [:service, :directory, :generic_network_interface_aws, :aws],

    [:service, :directory, :iscsi_volume, :generic],
    [:service, :directory, :iscsi_volume, :iscsi_volume_aws, :aws],
    [:service, :directory, :generic_iscsi_volume_aws, :aws],

    [:service, :directory, :volume, :generic],
    [:service, :directory, :volume, :volume_aws, :aws],
    [:service, :directory, :generic_volume_aws, :aws],
    [:service, :directory, :new_relic],
    [:service, :directory, :generic_new_relic],

    [:service, :directory, :internet_gateway, :generic],
    [:service, :directory, :internet_gateway, :internet_gateway_aws, :aws],
    [:service, :directory, :generic_internet_gateway_aws, :aws],

    [:service, :directory, :route_table, :generic],
    [:service, :directory, :route_table, :route_table_aws, :aws],
    [:service, :directory, :generic_route_table_aws, :aws],

    [:service, :directory, :security_group, :generic],
    [:service, :directory, :security_group, :security_group_aws, :aws],
    [:service, :directory, :generic_security_group_aws, :aws],

    [:service, :directory, :subnet_group, :generic],
    [:service, :directory, :subnet_group, :subnet_group_aws, :aws],
    [:service, :directory, :generic_subnet_group_aws, :aws],

    [:service, :directory, :elastic_ip, :generic],
    [:service, :directory, :elastic_ip, :elastic_ip_aws, :aws],
    [:service, :directory, :generic_elastic_ip_aws, :aws],

    [:service, :directory, :auto_scaling, :generic],
    [:service, :directory, :auto_scaling, :auto_scaling_aws, :aws],
    [:service, :directory, :generic_auto_scaling_aws, :aws],

    [:service, :directory, :auto_scaling_configuration, :generic],
    [:service, :directory, :auto_scaling_configuration, :auto_scaling_configuration_aws, :aws],
    [:service, :directory, :generic_auto_scaling_configuration_aws, :aws],

    [:service, :directory, :alarm, :generic],
    [:service, :directory, :alarm, :alarm_aws, :aws],
    [:service, :directory, :generic_alarm_aws, :aws],

    [:service, :directory, :rds, :generic],
    [:service, :directory, :rds, :rds_aws, :aws, :postgres],
    [:service, :directory, :rds, :rds_aws, :aws, :mysql],
    [:service, :directory, :rds, :rds_aws, :aws, :sqlserver_ee],
    [:service, :directory, :rds, :rds_aws, :aws, :sqlserver_ex],
    [:service, :directory, :rds, :rds_aws, :aws, :sqlserver_se],
    [:service, :directory, :rds, :rds_aws, :aws, :sqlserver_web],
    [:service, :directory, :rds, :rds_aws, :aws, :oracle_se1],
    [:service, :directory, :rds, :rds_aws, :aws, :oracle_se],
    [:service, :directory, :rds, :rds_aws, :aws, :oracle_ee],
    [:service, :directory, :rds, :rds_aws, :aws, :aurora_db],
    [:service, :directory, :generic_rds_aws, :aws, :postgres],
    [:service, :directory, :generic_rds_aws, :aws, :mysql],
    [:service, :directory, :generic_rds_aws, :aws, :sqlserver_ee],
    [:service, :directory, :generic_rds_aws, :aws, :sqlserver_ex],
    [:service, :directory, :generic_rds_aws, :aws, :sqlserver_se],
    [:service, :directory, :generic_rds_aws, :aws, :sqlserver_web],
    [:service, :directory, :generic_rds_aws, :aws, :oracle_se1],
    [:service, :directory, :generic_rds_aws, :aws, :oracle_se],
    [:service, :directory, :generic_rds_aws, :aws, :oracle_ee],
    [:service, :directory, :generic_rds_aws, :aws, :aurora_db],
    [:service, :directory, :rds, :rds_azure, :azure]

  ].each do |factory_attributes|
    attributes = FactoryBot.attributes_for(*factory_attributes).slice!(:data)
    Service.where(attributes).directory.first || FactoryBot.create(*factory_attributes)
  end
end

def populate_access_rights

    generate_access_rights = []
    
    rights_hash = Settings.rights.each_with_object({}) { |obj, hash| hash[obj.code] = obj.title }
    rights_hash.each do |code, title|
      access = AccessRight.find_or_initialize_by(code: code) do |access_right|
        access_right.id = SecureRandom.uuid
        access_right.title = title
      end
      generate_access_rights.push(access)
    end
    AccessRight.import generate_access_rights, on_duplicate_key_update: {conflict_target: [:id], columns: [:title, :code] }
    
end


def update_synchronization_status_if_running
  Synchronization.find_in_batches do |group|
    group.each do |sync|
      sync.state_info.delete("auto_sync")
      if sync.auto_sync_to_cs_from_aws.nil?
        sync.state_info.merge!(auto_sync_to_cs_from_aws: false) 
        sync.state_info_will_change!
        sync.save
      end
    end
  end
  Adapter.where(sync_running: true).update_all(sync_running: false)
end

# def update_machine_image_configuration
#   CSLogger.info "Total Configurations are #{MachineImageConfiguration.count}"
#   MachineImageConfiguration.where(is_template: false).find_in_batches do|configs|
#     configs.each do|config|
#       unless config.organisation_image.blank?
#         config.account_id = config.organisation_image.account_id
#         config.save
#       end
#     end
#   end
# end

#Create default storages
def create_default_storage
  Adapters::AWS.bucket_present.each do |adapter|
    if adapter.bucket_id.present?
      Storages::AWS.find_or_create_by(
        :adapter => adapter,
        :key => adapter.bucket_id,
        :account => adapter.account
      ) do |storage|
        storage.region_id = adapter.bucket_region_id
        creation_date = Time.now
      end
    end
  end if ENV['SAAS_ENV'] == false || ENV['SAAS_ENV'] == 'false'
end
 

# def update_volume_snapshot_id
#   Services::Compute::Server::Volume::AWS.find_in_batches do |group|
#     group.each { |volume|
#       next if volume.data.nil?
#       if volume.data["snapshot_id"].present?
#         volume.destination_snapshot_id=volume.data["snapshot_id"]
#         volume.data.merge!("snapshot_id"=>"")
#         volume.data_will_change!
#       end
#       if volume.data["snapshot_provider_id"].present?
#         volume.destination_snapshot_provider_id=volume.data["snapshot_provider_id"]
#         volume.data.merge!("snapshot_provider_id"=>"")
#         volume.data_will_change!
#       end
#       volume.save!
#     }
#   end
# end

def run_onetime_methods(onetime_methods)
  ScriptRunStatus.where(:script_type.in => onetime_methods).each do |script_status|
    unless script_status.run_status
      begin
        eval script_status.script_type
        script_status.update(run_status: true)
      rescue Exception => e
        script_status.update(run_status: false)
        CSLogger.error "#{e.message}-------#{e.backtrace}"
      end
    end
  end
end

def run_onetime_rake_tasks(onetime_rake_tasks)
  ScriptRunStatus.where(:script_type.in => onetime_rake_tasks).each do |script_status|
    unless script_status.run_status
      begin
        CSLogger.info "calling rake task #{script_status.script_type}"
        sys_call = "bundle exec rake #{script_status.script_type}"
        if system(sys_call)
          script_status.update(run_status: true)
        end
      rescue Exception => e
        script_status.update(run_status: false)
        CSLogger.error "#{e.message}-------#{e.backtrace}"
      end
    end
  end
end

def create_or_find_mira_endpoint
  mira_endpoint_names = ['Auth URL', 'Recommendation URL', 'Web Host URL']
  mira_endpoint_names.each do |mira_endpoint_name|
    MiraEndpoint.find_or_create_by(name: mira_endpoint_name)
  end
end

def run_deployment_rake_tasks
  deployment_rake_tasks.each do |task_name|
    begin
      if system("bundle exec rake #{task_name}")
        puts " Rake execution completed for --> #{task_name}"
      else
        puts "Failed to run rake --> #{task_name}"
      end
    rescue Exception => e
      puts "#{e.message}-------#{e.backtrace}"
    end
  end
end

run_onetime_methods(onetime_methods)
run_onetime_rake_tasks(onetime_rake_tasks)

populate_proividers
populate_access_rights
create_region_if_not_available
update_synchronization_status_if_running
create_or_find_mira_endpoint
run_deployment_rake_tasks
