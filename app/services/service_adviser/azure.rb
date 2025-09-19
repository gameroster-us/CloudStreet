require "./lib/node_manager.rb"
require 'will_paginate/array'
class ServiceAdviser::Azure < CloudStreetService
  extend ServiceAdviser::Helpers::Common
  
  IGNORE_CATEGORY_UNUSED = %w[
    idle_vm idle_lbs
    idle_databases
    idle_stopped_vm
    idle_disks
    unassociated_lbs
    unassociated_public_ips
    unattached_disks
    unassociated_snapshots
    idle_elastic_pools
    idle_blob_services
    idle_app_service_plans
    unused_app_service_plans
    idle_aks
  ].freeze

  IGNORE_CATEGORY_UNOPTIMIZED = %w[vm_right_sizings sqldb_right_sizings].freeze
  APPLICABLE_DB_TYPES = ["Azure::Resource::Database::MySQL::Server", "Azure::Resource::Database::MariaDB::Server", "Azure::Resource::Database::PostgreSQL::Server", "Azure::Resource::Database::SQL::DB"].freeze

  # get only count of service adviser
  # for all service & particualr service
  def self.list_service_type_with_count(filters, account, tenant, user, current_tenant_currency_rates, &block)
    response_array = []
    filters = filters.keep_if { |h| !filters[h].nil? && !filters[h].empty? }
    tags = filters.delete(:tags)
    tags = tags.present? ? tags : []
    filters[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(tenant, 'Adapters::Azure', filters[:adapter_id])
    filters[:resource_group_id] = tenant.azure_resource_group_ids
    filters[:tenant_tags] = tenant.tags.present? ? [tenant.tags] : []
    filters[:region_id] = get_enabled_region_ids(account, filters[:adapter_id]) if !filters.key?(:region_id) || filters[:region_id].blank?
    filters[:account] = account
    idle_vm = get_idle_vm(filters, tags, true)  if (filters[:service_type].present? && filters[:service_type].eql?("idle_vm")) || !filters[:service_type].present?
    idle_stopped_vm = get_idle_stopped_vm(filters, tags, true)  if (filters[:service_type].present? && filters[:service_type].eql?("idle_stopped_vm")) || !filters[:service_type].present?
    idle_databases = get_idle_databases(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?("idle_databases")) || !filters[:service_type].present?
    idle_disks = get_idle_disks(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?("idle_disks")) || !filters[:service_type].present?
    idle_lbs = get_idle_lbs(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('idle_lbs')) || !filters[:service_type].present?
    unassociated_lbs = get_unassociated_lbs(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('unassociated_lbs')) || !filters[:service_type].present?
    unassociated_public_ips = get_unassociated_public_ips(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('unassociated_public_ips')) || !filters[:service_type].present?
    unattached_disks = get_unattached_disks(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('unattached_disks')) || !filters[:service_type].present?
    unused_snapshots = get_unused_snapshots(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('unused_snapshots')) || !filters[:service_type].present?
    idle_elastic_pools = get_idle_elastic_pools(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('idle_elastic_pools')) || !filters[:service_type].present?
    idle_blob_services = get_idle_blob_services(filters, tags, true) if (filters[:service_type].present? && filters[:service_type].eql?('idle_blob_services')) || !filters[:service_type].present?
    idle_app_service_plans = get_idle_app_service_plans(filters, tags, true) if filters[:service_type].blank? || filters[:service_type].eql?('idle_app_service_plans')
    unused_app_service_plans = get_unused_app_service_plans(filters, tags, true) if filters[:service_type].blank? || filters[:service_type].eql?('unused_app_service_plans')
    idle_aks = get_idle_aks(filters, tags, true)  if (filters[:service_type].present? && filters[:service_type].eql?("idle_aks")) || !filters[:service_type].present?

    unless idle_vm.blank?
      response_array << {"type" => "idle_vm", "count" => idle_vm[:count], "cost_sum" => idle_vm[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_vm[:count].zero?
    end
    unless idle_stopped_vm.blank?
      response_array << {"type" => "idle_stopped_vm", "count" => idle_stopped_vm[:count], "cost_sum" => idle_stopped_vm[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_stopped_vm[:count].zero?
    end
    unless idle_databases.blank?
      response_array << {"type" => "idle_databases", "count" => idle_databases[:count], "cost_sum" => idle_databases[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_databases[:count].zero?
    end
    unless idle_disks.blank?
      response_array << {"type" => "idle_disks", "count" => idle_disks[:count], "cost_sum" => idle_disks[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_disks[:count].zero?
    end
    unless unassociated_lbs.blank?
      response_array << { type: 'unassociated_lbs', count: unassociated_lbs[:count], cost_sum: unassociated_lbs[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless unassociated_lbs[:count].zero? 
    end
    unless idle_lbs.blank?
      response_array << { type: 'idle_lbs', count: idle_lbs[:count], cost_sum: idle_lbs[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_lbs[:count].zero?
    end
    unless unassociated_public_ips.blank?
      response_array << { type: 'unassociated_public_ips', count: unassociated_public_ips[:count], cost_sum: unassociated_public_ips[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless unassociated_public_ips[:count].zero?
    end
    unless unattached_disks.blank?
      response_array << { type: 'unattached_disks', count: unattached_disks[:count], cost_sum: unattached_disks[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless unattached_disks[:count].zero?
    end
    unless unused_snapshots.blank?
      response_array << { type: 'unused_snapshots', count: unused_snapshots[:count], cost_sum: unused_snapshots[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless unused_snapshots[:count].zero?
    end
    unless idle_elastic_pools.blank?
      response_array << { type: 'idle_elastic_pools', count: idle_elastic_pools[:count], cost_sum: idle_elastic_pools[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_elastic_pools[:count].zero?
    end
    unless idle_blob_services.blank?
      response_array << { type: 'idle_blob_services', count: idle_blob_services[:count], cost_sum: idle_blob_services[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_blob_services[:count].zero?
    end
    unless idle_app_service_plans.blank?
      response_array << { type: 'idle_app_service_plans', count: idle_app_service_plans[:count], cost_sum: idle_app_service_plans[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_app_service_plans[:count].zero?
    end
    unless unused_app_service_plans.blank?
      response_array << { type: 'unused_app_service_plans', count: unused_app_service_plans[:count], cost_sum: unused_app_service_plans[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless unused_app_service_plans[:count].zero?
    end
    unless idle_aks.blank?
      response_array << { type: 'idle_aks', count: idle_aks[:count], cost_sum: idle_aks[:cost_sum] * 24 * 30 * current_tenant_currency_rates[1], "currency" => current_tenant_currency_rates[0] } unless idle_aks[:count].zero?
    end
    return response_array unless block_given?

    assignable_environments = []
    response = {service_type_count: response_array, assignable_environments: assignable_environments, currency: current_tenant_currency_rates[0] }
    status Status, :success, response, &block
  rescue ActionController::ParameterMissing => e
    status Status, :error, e, &block
  rescue Exception => e
    status Status, :error, e, &block
  end

  #to get details list of a particular service in service adviser
  def self.list_service_type_with_detail(filters, paginate, sort, account, tenant, user, &block)
    raise ActionController::ParameterMissing, :service_type if filters[:service_type].blank?
    
    tags = filters.delete(:tags)
    tags = tags.present? ? tags : []    
    filters[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(tenant, 'Adapters::Azure', filters[:adapter_id])
    filters[:resource_group_id] = tenant.azure_resource_group_ids
    unless sort.blank?
      sort = nil unless %w[created_at cost_by_hour].any? { |word| sort.include?(word) }
      sort = format_sort(sort, filters[:service_type]) if sort.present?
    end
    filters = filters.keep_if { |h| !filters[h].nil? && !filters[h].empty? }
    filters[:tenant_tags] = tenant.tags.present? ? [tenant.tags] : []
    filters[:region_id] = get_enabled_region_ids(account, filters[:adapter_id]) if !filters.key?(:region_id) || filters[:region_id].blank?
    filters[:account] = account
    services = {}
    total_service_count = nil
    unless filters[:service_type].blank?
      if filters[:service_type].eql?("idle_vm")
        services = get_idle_vm(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?("idle_stopped_vm")
        services = get_idle_stopped_vm(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?("idle_databases")
        services = get_idle_databases(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?("idle_disks")
        services = get_idle_disks(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('unassociated_lbs')
        services = get_unassociated_lbs(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('idle_lbs')
        services = get_idle_lbs(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('unassociated_public_ips')
        services = get_unassociated_public_ips(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('unattached_disks')
        services = get_unattached_disks(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('unused_snapshots')
        services = get_unused_snapshots(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('idle_elastic_pools')
        services = get_idle_elastic_pools(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('idle_blob_services')
        services = get_idle_blob_services(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('idle_app_service_plans')
        services = get_idle_app_service_plans(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?('unused_app_service_plans')
        services = get_unused_app_service_plans(filters, tags, false, false, sort, paginate)
      elsif filters[:service_type].eql?("idle_aks")
        services = get_idle_aks(filters, tags, false, false, sort, paginate)
      end
      total_service_count = services.blank? ? 0 : services.count
    end

    services.each do |s|
      s.comment_count = ServiceDetail.where(adapter_id: s.adapter_id,
                                            region_id: s.region_id,
                                            provider_id: s.provider_data['id']).count
    end
    
    response = { total_service_count: total_service_count, services: services }
    status Status, :success, response, &block
  rescue ActionController::ParameterMissing => e
    status Status, :error, e, &block
  rescue Exception => e
    status Status, :error, e, &block
  end

  def self.get_idle_aks(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Container::AKS.active
                                 .where(applicable_filters)
                                 .idle_resources
                                 .running_aks
                                 .not_ignored_from(['idle_aks'])
                                 .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?    
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_vm(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Compute::VirtualMachine.active
                                                       .exclude_aks_resource_group_services
                                                       .exclude_databricks_resource_group_services
                                                       .where(applicable_filters)
                                                       .running_vm
                                                       .not_ignored_from(['idle_vm'])
                                                       .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_stopped_vm(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Compute::VirtualMachine.active
                                                       .exclude_aks_resource_group_services
                                                       .exclude_databricks_resource_group_services
                                                       .where(applicable_filters)
                                                       .stopped_vm
                                                       .not_ignored_from(['idle_stopped_vm'])
                                                       .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_databases(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id], type: APPLICABLE_DB_TYPES, idle_instance: true}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Database.uncached do
                Azure::Resource::Database.active
                                          .where(applicable_filters)
                                          .only_running
                                          .exclude_elastic_pool_dbs
                                          .exclude_aks_resource_group_services
                                          .exclude_databricks_resource_group_services
                                          .exclude_data_warehouse_resources
                                          .not_ignored_from(['idle_databases'])
                                          .filter_resource_group(filters[:resource_group_id])
              end
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_disks(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Compute::Disk.where(applicable_filters)
                                             .active
                                             .attached
                                             .data_disks
                                             .exclude_active_sas
                                             .exclude_aks_resource_group_services
                                             .exclude_databricks_resource_group_services
                                             .not_ignored_from(['idle_disks'])
                                             .by_retention_period
                                             .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_unassociated_lbs(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?

    services = Azure::Resource::Network::LoadBalancer.where(applicable_filters)
                                                     .active
                                                     .standard_lbs
                                                     .exclude_aks_resource_group_services
                                                     .exclude_databricks_resource_group_services
                                                     .unattached
                                                     .not_ignored_from(['unassociated_lbs'])
                                                     .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?                                              
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_lbs(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?

    services = Azure::Resource::Network::LoadBalancer.where(applicable_filters)
                                                     .active
                                                     .standard_lbs
                                                     .exclude_aks_resource_group_services
                                                     .exclude_databricks_resource_group_services
                                                     .not_ignored_from(['idle_lbs'])
                                                     .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_unassociated_public_ips(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?

    services = Azure::Resource::Network::PublicIPAddress.where(applicable_filters)
                                                        .active
                                                        .unassociated
                                                        .only_non_zero
                                                        .exclude_aks_resource_group_services
                                                        .exclude_databricks_resource_group_services
                                                        .not_ignored_from(['unassociated_public_ips'])
                                                        .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_unattached_disks(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?

    services = Azure::Resource::Compute::Disk.where(applicable_filters)
                                              .active
                                              .exclude_aks_resource_group_services
                                              .exclude_databricks_resource_group_services
                                              .unattached
                                              .not_ignored_from(['unattached_disks'])
                                              .by_retention_period
                                              .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_unused_snapshots(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    snapshots_in_use = Azure::Resource::Compute::Disk.active.where(applicable_filters).pluck("provider_data->'creation_data'->'source_resource_id'").compact
    snapshots_in_use << '' if snapshots_in_use.blank?
    account = filters[:account]
    snaphot_config = account.service_adviser_configs.azure_snapshot_default_config


    services = Azure::Resource::Compute::Snapshot.where(applicable_filters)
                                                 .where.not("provider_data->>'id' in (?)", snapshots_in_use)
                                                 .active
                                                 .exclude_aks_resource_group_services
                                                 .exclude_databricks_resource_group_services
                                                 .not_ignored_from(['unused_snapshots'])
                                                 .by_retention_period(snaphot_config.snapshot_retention_period)
                                                 .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present? 
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_elastic_pools(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Database::SQL::ElasticPool.where(applicable_filters)
                                                          .active
                                                          .not_ignored_from(['idle_elastic_pools'])
                                                          .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_blob_services(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id], idle_instance: true }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Blob.where(applicable_filters)
                                    .active
                                    .not_ignored_from(['idle_blob_services'])
                                    .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_idle_app_service_plans(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Web::AppServicePlan.where(applicable_filters)
                                                   .active
                                                   .idle_resources
                                                   .exclude_shared_plans
                                                   .exclude_free_plans
                                                   .in_used_plans
                                                   .not_ignored_from('idle_app_service_plans')
                                                   .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_unused_app_service_plans(filters, tags = [], only_count = false, summary_data = false, sort = nil, paginate = {})
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    services = Azure::Resource::Web::AppServicePlan.where(applicable_filters)
                                                   .active
                                                   .unused_plans
                                                   .exclude_shared_plans
                                                   .exclude_free_plans
                                                   .not_ignored_from('unused_app_service_plans')
                                                   .filter_resource_group(filters[:resource_group_id])
    services = filter_services_by_tags(services, filters[:tenant_tags], tags, 'OR') if filters[:tenant_tags].any? || tags.present?
    services = sort_and_paginate_resources(services.ids, sort, paginate) if paginate.present?
    get_formated_response(services, only_count, summary_data, sort)
  end

  def self.get_right_size_vm_key_values(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    subscription_ids = Adapter.azure_adapter.where(id: filters[:adapter_id]).map(&:subscription_id).compact
    right_sized_vm_provider_ids = Azure::Rightsizing.vm.where(subscription_id: {'$in' => subscription_ids}).pluck(:provider_id)

    Azure::Resource::Compute::VirtualMachine.where("provider_data ->> 'id' IN(?)", right_sized_vm_provider_ids).where(applicable_filters)
                                            .active
                                            .exclude_aks_resource_group_services
                                            .exclude_databricks_resource_group_services
                                            .find_with_tags(filters[:tenant_tags], 'OR')
                                            .find_with_tags(tags, filters[:tag_operator])
                                            .filter_resource_group(filters[:resource_group_id])   
  end

  def self.get_ahub_vm_services(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    subscription_ids = Adapter.azure_adapter.where(id: filters[:adapter_id]).map(&:subscription_id).compact
    right_sized_vm_provider_ids = Azure::Rightsizing.ahub_vm.where(subscription_id: {'$in' => subscription_ids}).pluck(:provider_id)

    Azure::Resource::Compute::VirtualMachine.where("provider_data ->> 'id' IN(?)", right_sized_vm_provider_ids).where(applicable_filters)
                                            .active.ahub_eligible_vms
                                            .exclude_aks_resource_group_services
                                            .exclude_databricks_resource_group_services
                                            .find_with_tags(filters[:tenant_tags], 'OR')
                                            .find_with_tags(tags, filters[:tag_operator])
                                            .filter_resource_group(filters[:resource_group_id])
  end

  def self.get_ahub_sql_db_services(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    subscription_ids = Adapter.azure_adapter.where(id: filters[:adapter_id]).map(&:subscription_id).compact
    recommend_sql_db_provider_ids = Azure::Recommend.ahub_sql_db.where(subscription_id: {'$in' => subscription_ids}).pluck(:provider_id)

    Azure::Resource::Database::SQL::DB.where("provider_data ->> 'id' IN(?)", recommend_sql_db_provider_ids).where(applicable_filters)
                                            .active.ahub_eligible_sql_dbs
                                            .exclude_aks_resource_group_services
                                            .exclude_databricks_resource_group_services
                                            .find_with_tags(filters[:tenant_tags], 'OR')
                                            .find_with_tags(tags, filters[:tag_operator])
                                            .filter_resource_group(filters[:resource_group_id])
  end

  def self.get_right_size_sqldb_key_values(filters, tags=[], only_count=false, summary_data=false, sort=nil, paginate={})
    applicable_filters = {adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    subscription_ids = Adapter.azure_adapter.where(id: filters[:adapter_id]).map(&:subscription_id).compact
    right_sized_sqldb_provider_ids = Azure::Rightsizing.sqldb.where(subscription_id: {'$in' => subscription_ids}).pluck(:provider_id)
    
    Azure::Resource::Database::SQL::DB.where("provider_data ->> 'id' IN(?)", right_sized_sqldb_provider_ids).where(applicable_filters)
                                      .active
                                      .exclude_data_warehouse_resources
                                      .find_with_tags(tags, filters[:tag_operator])
                                      .filter_resource_group(filters[:resource_group_id])
  end

  def self.get_ahub_sql_elastic_pool_services(filters)
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    ahub_recommended_elastic_pools = Azure::Recommend.get_ahub_sql_elastic_pool_recommendation(applicable_filters)
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    Azure::Resource::Database::SQL::ElasticPool.where("provider_data ->> 'id' IN(?)", ahub_recommended_elastic_pools.pluck(:provider_id))
                                               .where(applicable_filters)
                                               .active
                                               .ahub_eligible_elastic_pool
                                               .exclude_aks_resource_group_services
                                               .exclude_databricks_resource_group_services
  end

  def self.get_vm_rightsizings(account, filters, summary_data=true)
    adapter_key_value = Adapters::Azure.where(id: filters[:adapter_id]).pluck("data->'subscription_id', id").to_h
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    vm_services = Azure::Resource::Compute::VirtualMachine.where(applicable_filters).active.running_vm.exclude_aks_resource_group_services.exclude_databricks_resource_group_services.not_ignored_from(["vm_right_sizings"])
    unless filters[:tenant_tags].first.blank?
      vm_services = vm_services.find_with_tags(filters[:tenant_tags], 'OR', account)
    end
    summary_data_count = []
    if vm_services.size
      vm_rightsizings = Azure::Rightsizing.where(resource_type: 'vm', :provider_id.in => vm_services.pluck("provider_data->>'id'"), account_id: account.id)
      vm_rightsizings.group_by(&:subscription_id).each do |subscription_id, services|
        summary_data_count << {"adapter_id" =>  adapter_key_value[subscription_id], "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.costsavedpermonth unless s.costsavedpermonth.blank? } }
      end
    end
    summary_data_count
  end

  def self.get_sql_db_rightsizings(account, filters, summary_data=true)
    adapter_key_value = Adapters::Azure.where(id: filters[:adapter_id]).pluck("data->'subscription_id', id").to_h
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    sql_db_services = Azure::Resource::Database::SQL::DB.where(applicable_filters).active.only_running.exclude_aks_resource_group_services.exclude_databricks_resource_group_services.not_ignored_from(["sqldb_right_sizings"])
    unless filters[:tenant_tags].first.blank?
      sql_db_services = sql_db_services.find_with_tags(filters[:tenant_tags], 'OR', account)
    end
    summary_data_count = []
    if sql_db_services.size
      sql_db_rightsizings = Azure::Rightsizing.where(resource_type: 'sqldb', :provider_id.in => sql_db_services.pluck("provider_data->>'id'"))
      sql_db_rightsizings.group_by(&:subscription_id).each do |subscription_id, services|
        summary_data_count << {"adapter_id" =>  adapter_key_value[subscription_id], "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.costsavedpermonth unless s.costsavedpermonth.blank? } }
      end
    end
    summary_data_count
  end

  def self.get_vm_ahubs(account, filters, summary_data=true)
    adapter_key_value = Adapters::Azure.where(id: filters[:adapter_id]).pluck("data->'subscription_id', id").to_h
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id]}
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    ahub_vm_services = ::Azure::Resource::Compute::VirtualMachine.where(applicable_filters).active.ahub_eligible_vms.exclude_aks_resource_group_services.exclude_databricks_resource_group_services
    unless filters[:tenant_tags].first.blank?
      ahub_vm_services = ahub_vm_services.find_with_tags(filters[:tenant_tags], 'OR', account)
    end
    summary_data_count = []
    if ahub_vm_services.size
      ahub_vms = ::Azure::Rightsizing.where(resource_type: 'ahub_vm', :provider_id.in => ahub_vm_services.pluck("provider_data->>'id'"), account_id: account.id)
      ahub_vms.group_by(&:subscription_id).each do |subscription_id, services|
        summary_data_count << {"adapter_id" =>  adapter_key_value[subscription_id], "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.costsavedpermonth unless s.costsavedpermonth.blank? } }
      end
    end
    summary_data_count
  end

  def self.get_sql_ahubs(account, filters, summary_data=true)
    adapter_key_value = Adapters::Azure.where(id: filters[:adapter_id]).pluck("data->'subscription_id', id").to_h
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    ahub_sql_db_services = ::Azure::Resource::Database::SQL::DB.where(applicable_filters).active.ahub_eligible_sql_dbs.exclude_aks_resource_group_services.exclude_databricks_resource_group_services
    unless filters[:tenant_tags].first.blank?
      ahub_sql_db_services = ahub_sql_db_services.find_with_tags(filters[:tenant_tags], 'OR', account)
    end
    summary_data_count = []
    if ahub_sql_db_services.size
      ahub_sql_dbs = ::Azure::Recommend.where(resource_type: 'ahub_sql_db', :provider_id.in => ahub_sql_db_services.pluck("provider_data->>'id'"), account_id: account.id)
      ahub_sql_dbs.group_by(&:subscription_id).each do |subscription_id, services|
        summary_data_count << {"adapter_id" =>  adapter_key_value[subscription_id], "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.costsavedpermonth unless s.costsavedpermonth.blank? } }
      end
    end
    summary_data_count
  end

  def self.get_elastic_pool_ahubs(account, filters, summary_data=true)
    adapter_key_value = Adapters::Azure.where(id: filters[:adapter_id]).pluck("data->'subscription_id', id").to_h
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    applicable_filters.merge!(azure_resource_group_id: filters[:azure_resource_group_id]) if filters[:azure_resource_group_id].present?
    ahub_elastic_pool_services = ::Azure::Resource::Database::SQL::ElasticPool.where(applicable_filters).active.ahub_eligible_elastic_pool.exclude_aks_resource_group_services.exclude_databricks_resource_group_services
    unless filters[:tenant_tags].first.blank?
      ahub_elastic_pool_services = ahub_elastic_pool_services.find_with_tags(filters[:tenant_tags], 'OR', account)
    end
    summary_data_count = []
    if ahub_elastic_pool_services.size
      ahub_elastic_pools = ::Azure::Recommend.where(resource_type: 'ahub_sql_elastic_pool', :provider_id.in => ahub_elastic_pool_services.pluck("provider_data->>'id'"), account_id: account.id)
      ahub_elastic_pools.group_by(&:subscription_id).each do |subscription_id, services|
        summary_data_count << {"adapter_id" =>  adapter_key_value[subscription_id], "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.costsavedpermonth unless s.costsavedpermonth.blank? } }
      end
    end
    summary_data_count
  end

  def self.sort_and_paginate_resources(service_ids, sort, paginate)
    Azure::Resource.where(id: service_ids).order(sort).paginate(paginate)
  end

  def self.get_enabled_region_ids(account, adapter_id)
    adapter = Adapter.find(adapter_id)
    account = adapter.account if account.blank?
    account.get_enabled_regions("Azure").pluck(:id)
  end

  #to get acutal formated response for three different part of service adviser (summary, count , details)
  def self.get_formated_response(services, only_count=false, summary_data=false, sort=nil, paginate={})
    if only_count
      service_costs = services.pluck(:cost_by_hour).compact
      { count: service_costs.count, cost_sum: service_costs.sum }
    elsif summary_data
      summary_data_count = []
      services.group_by(&:adapter_id).each do |adapter_id, services|
        summary_data_count << {"adapter_id" => adapter_id, "count" => services.size, "cost_sum" => services.inject(0) { |sum, s| sum + s.cost_by_hour unless s.cost_by_hour.blank? } }
      end
      summary_data_count
    else
      services
      # ServiceAdviser::Base.sort_idle_services(services, sort, paginate)
    end
  end

  def self.get_azure_resource_groups(account, tenant, filters, &block)
    adapter_ids = ServiceAdviser::Base.fetch_normal_adapter_ids(tenant, 'Adapters::Azure', filters[:adapter_id], filters[:adapter_group_id])
    if filters[:region_id].present?
      region_ids = filters[:region_id]
    else
      region_ids = account.get_enabled_regions("Azure").ids
    end
    resource_groups = Azure::ResourceGroup.where(adapter_id: adapter_ids, region_id: region_ids).active.exclude_aks_databricks_resource_group.select(:id, :name, :provider_id, :region_id, :state)
    resource_groups = resource_groups.filter_resource_group(tenant.azure_resource_group_ids)
    response = resource_groups.blank? ? {} : resource_groups
    status Status, :success, resource_groups, &block
  end

  def self.recommended_csv(result, service_type, current_account)
    region_id_wise_map = Region.azure_region_id_map
    CS_configured_tag_keys = current_account.tags.pluck(:tag_key)
    adapter_map = current_account.organisation.adapters.azure_adapter.each_with_object({}) { |adapter, memo| memo[adapter.id] = adapter.slice(:name, :subscription_id) }
    result = result[:services]
    attributes = %w[resource_name Subscription_Id Subscription_Name service_id resource_group service_type state region usage_cost MEC days_old task_status tags additional_information]
    attributes.delete('days_old') unless %w[unused_snapshots unattached_disks idle_disks].include?(service_type)
    attributes.delete('state') if %w[unassociated_public_ips].include?(service_type)
    attributes.delete('tags') if %w[idle_blob_services].include?(service_type)

    idle_csv(result, region_id_wise_map, service_type, CS_configured_tag_keys, attributes, adapter_map)
  end

  def self.idle_csv(result, region_id_wise_map, service_type, CS_configured_tag_keys, attributes, adapter_map)
    csv = CSV.generate(headers: true) do |csv|
      csv << attributes.map { |attr| %w[MEC MES].include?(attr) ? attr : %w[Subscription_Id Subscription_Name].include?(attr) ? attr.tr('_', ' ') : attr.titleize }
      result.each do |record|
        csv << attributes.map do |attr|
          attr.strip!
          if attr.eql? 'Subscription_Id'
            adapter_map[record.adapter_id]['subscription_id'] || 'N/A'
          elsif attr.eql? 'Subscription_Name'
            adapter_map[record.adapter_id]['name'] || 'N/A'
          elsif attr.eql? 'resource_name'
            record.name
          elsif attr.eql? 'service_id'
            record.provider_id
          elsif attr.eql? 'region'
            region_id_wise_map[record.region_id].try(:region_name)
          elsif attr.eql? 'usage_cost'
            record.usage_cost.to_f.try(:round, 2) || 'N/A'
          elsif attr.eql? 'MEC'
            potential_price = record.monthly_estimated_cost
            potential_price.try(:round, 2)
          elsif attr.eql? 'tags'
            record.service_tags.present? ? record.service_tags.each_with_object({}) { |m, memo| memo[m.key.tr('#;', '')] = m.value.tr('#', '').tr(';','') } : "N/A"
            #record.service_tags.present? ? record.service_tags.each_with_object({}) { |m, memo| memo[m.key] = m.value } : "N/A"
          elsif attr.eql? 'additional_information'
            record.additional_information.present? ? record.additional_information.to_h : "N/A"
          elsif attr.eql? 'task_status'
            record.sa_recommendation_status.eql?('N/A')? record.sa_recommendation_status : record.sa_recommendation_status&.capitalize
          else
            record.send(attr)
          end
        end
      end
    end
  end

  def self.get_service_advisor_recommendations_report_csv(user, current_tenant, current_account, params, current_tenant_currency_rates, &block)
    options = {
      user_id: user.id,
      account_id: current_account.id,
      tenant_id: current_tenant.id,
      current_tenant_currency_rates: current_tenant_currency_rates
    }
    ServiceAdviserSummaryWorker.perform_async(params.to_unsafe_h, options)

    status Status, :success, {success: 'Export request initiated. Report will be mailed to your registered email address.'}, &block
  rescue Exception => e
    CSLogger.error "Error in exporting CSV file= #{e.message}"
    CSLogger.error e.backtrace
    status Status, :error, e.message, &block
  end

  def self.get_key_values_array(filters, current_tenant, current_account, &block)
    #adapter_ids = filters[:adapter_id].present? ? Array[*filters[:adapter_id]] : current_tenant.adapters.normal_adapters.available.azure_adapter.map(&:id)
    region_ids = filters[:region_id].present? ? Array[*filters[:region_id]] : get_enabled_region_ids(current_tenant.organisation.account, filters[:adapter_id])
    applicable_filters = { adapter_id: filters[:adapter_id], region_id: region_ids , resource_group_id: current_tenant.azure_resource_group_ids}
    applicable_filters[:tenant_tags] = current_tenant.tags.present? ? [current_tenant.tags] : []
    applicable_filters[:account] = current_account
    idle_services_hash = build_combined_services_hash(applicable_filters)
    service_tags = idle_services_hash.each_with_object({}) { |(key, val), memo| memo.merge!(key => val.map { |el| el.tags.map { |tag| { tag['key'] => tag['value'] } } }.compact.flatten) }
    general_setting = current_tenant.organisation.account.general_setting
    service_tags = if general_setting&.is_tag_case_insensitive
                     service_tags.each_with_object({}) { |(key, value), memo| memo.merge!({ key => value.each_with_object({}) { |el, h| el.each { |k, v| h[k.downcase] = [* h[k.downcase] ? [*h[k.downcase]] << v&.downcase : v&.downcase].uniq.compact } } }) }
                   else
                     service_tags.each_with_object({}) { |(key, value), memo| memo.merge!({ key => value.each_with_object({}) { |el, h| el.each { |k, v| h[k] = [* h[k] ? [*h[k]] << v : v].uniq.compact } } }) }
                   end
    status Status, :success, service_tags, &block
  end

  def self.build_combined_services_hash(applicable_filters)
    {
      idle_vm: get_idle_vm(applicable_filters),
      idle_stopped_vm: get_idle_stopped_vm(applicable_filters),
      idle_databases: get_idle_databases(applicable_filters),
      idle_disks: get_idle_disks(applicable_filters),
      unassociated_lbs: get_unassociated_lbs(applicable_filters),
      idle_lbs: get_idle_lbs(applicable_filters),
      get_unassociated_public_ips: get_unassociated_public_ips(applicable_filters),
      unattached_disks: get_unattached_disks(applicable_filters),
      unused_snapshots: get_unused_snapshots(applicable_filters),
      vm_rightsizing: get_right_size_vm_key_values(applicable_filters),
      sqldb_rightsizing: get_right_size_sqldb_key_values(applicable_filters),
      idle_elastic_pools: get_idle_elastic_pools(applicable_filters),
      idle_blob_services: get_idle_blob_services(applicable_filters),
      ahub_vm_recommendations: get_ahub_vm_services(applicable_filters),
      ahub_sql_db_recommendations: get_ahub_sql_db_services(applicable_filters),
      ahub_sql_elastic_pool_recommendations: get_ahub_sql_elastic_pool_services(applicable_filters),
      idle_app_service_plans: get_idle_app_service_plans(applicable_filters),
      unused_app_service_plans: get_unused_app_service_plans(applicable_filters)
    }
  end

  def self.show_ignored_services(current_account, current_tenant, params, current_tenant_currency_rate, &block)
    params[:count] = params[:count].eql?('true') ? true : false
    applicable_filters = build_filters(current_tenant, current_account, params)
    ignore_service_details = ServiceDetail.azure_ignore_service_details.comment_type_ignored.where(applicable_filters)
    applicable_filters.merge!(azure_resource_group_id: params[:azure_resource_group_id]) if params[:azure_resource_group_id].present?
    params[:adapter_id] = applicable_filters[:adapter_id]
    params[:region_id] = applicable_filters[:region_id]
    params[:tenant_resource_group_ids] = current_tenant.azure_resource_group_ids
    ignored_services_hash = fetch_ignored_services(ignore_service_details, params ,current_account, current_tenant, current_tenant_currency_rate)
    response_data = if params[:count]
                      ignore_services_count_response(ignored_services_hash, current_tenant_currency_rate)
                    else
                      ignore_services_details_response(params, ignored_services_hash.symbolize_keys, current_tenant_currency_rate)
                    end
    status Status, :success, response_data, &block
  rescue StandardError => e
    status Status, :error, e, &block
  end

  def self.get_ignored_services_summary_for_csv(current_account, current_tenant, params, current_tenant_currency_rate, &block)
    params[:count] = params[:count].eql?('true') ? true : false
    params[:adapter_ids] = params[:adapter_id]
    applicable_filters = build_filters(current_tenant, current_account, params)
    ignore_service_details = ServiceDetail.azure_ignore_service_details.comment_type_ignored.where(applicable_filters)
    applicable_filters.merge!(azure_resource_group_id: params[:azure_resource_group_id]) if params[:azure_resource_group_id].present?
    params[:adapter_id] = applicable_filters[:adapter_id]
    params[:region_id] = applicable_filters[:region_id]
    params[:tenant_resource_group_ids] = current_tenant.azure_resource_group_ids

    response_data = []
    ignored_services_hash = fetch_ignored_services_for_csv(ignore_service_details, params ,current_account, current_tenant, current_tenant_currency_rate)

    ignored_services_hash.each do |res|
      response_data << ignore_services_details_response(params, res.symbolize_keys, current_tenant_currency_rate)
    end
    status Status, :success, response_data, &block
  rescue StandardError => e
    status Status, :error, e, &block
  end

  def self.build_filters(current_tenant, account, params)
    adapter_ids = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::Azure', params[:adapter_ids])
    params[:region_id] = params[:region_id].present? ? Array[* params[:region_id]] : account.get_enabled_regions('Azure').pluck(:id)
    {
      adapter_id: adapter_ids,
      region_id: params[:region_id]
    }
  end

  def self.fetch_ignored_services(ignore_service_details, filters, account, tenant, current_tenant_currency_rate)
    tags = filters[:tags].blank? ? [] : (JSON.parse(filters[:tags]) rescue [])
    category = filters.delete(:category)
    service_type = filters.delete(:service_type)
    ignore_service_details = ignore_service_details.where(ignored_from_category: service_type) if service_type.present?
    resource_urls = ignore_service_details.pluck(:provider_id).uniq
    filters[:tenant_tags] = tenant.tags.present? ? [tenant.tags] : []
    if filters[:count]
      services_from_unused = fetch_unused_ignored_services(resource_urls, filters, tags)
      services_from_unoptimized = fetch_unoptmized_ignored_sqldbs(resource_urls, filters, tags) + fetch_unoptmized_ignored_vms(resource_urls, filters, tags)
      { unused: services_from_unused, unoptimized: services_from_unoptimized }
    else
      if category.eql?('unoptimized')
        ignored_unoptimized = []
        ignored_rightsized_vms = ignored_rightsized_vms_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
        ignored_rightsized_sqldbs = ignored_rightsized_sqldbs_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
        # we can concat more ignored rightsized type fo instacnes
        # with ignored_unoptimized array
        ignored_unoptimized.concat(ignored_rightsized_vms, ignored_rightsized_sqldbs)
        { total_service_count: ignored_unoptimized.count, services: ignored_unoptimized}
      else
        ignored_resources = fetch_unused_ignored_services(resource_urls, filters, tags)
        format_unused_ignore_resources(ignored_resources, filters, current_tenant_currency_rate)
      end
    end
  end

  def self.fetch_ignored_services_for_csv(ignore_service_details, filters, account, tenant, current_tenant_currency_rate)
    response = []
    tags = filters[:tags].present? ? (JSON.parse(filters[:tags]) rescue []) : []
    category = filters.delete(:category)
    service_type = filters.delete(:service_type)
    azure_resource_group_id = filters.delete(:azure_resource_group_id) if filters[:azure_resource_group_id].blank?
    ignore_service_details = ignore_service_details.where(ignored_from_category: service_type) if service_type.present?
    resource_urls = ignore_service_details.pluck(:provider_id).uniq
    filters[:tenant_tags] = tenant.tags.present? ? [tenant.tags] : []
    ignored_unoptimized = []
    ignored_rightsized_vms = ignored_rightsized_vms_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
    ignored_rightsized_sqldbs = ignored_rightsized_sqldbs_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
    # we can concat more ignored rightsized type fo instacnes
    # with ignored_unoptimized array
    ignored_unoptimized.concat(ignored_rightsized_vms, ignored_rightsized_sqldbs)
    unoptimized_ignored_services = { total_service_count: ignored_unoptimized.count, services: ignored_unoptimized, service_type: 'Unoptimized Services'}
    response << unoptimized_ignored_services
    ignored_resources = fetch_unused_ignored_services(resource_urls, filters, tags)
    unused_ignored_services = format_unused_ignore_resources(ignored_resources, filters, current_tenant_currency_rate)
    unused_ignored_services.merge!(service_type: 'Unused Services')
    response << unused_ignored_services
    return response
  end

  def self.fetch_unoptmized_ignored_vms(resource_urls, filters, tags)
    applicable_filters = filters.slice(:adapter_id, :region_id, :azure_resource_group_id).as_json
    response_resources = Azure::Resource::Compute::VirtualMachine.filter_resource_group(filters[:tenant_resource_group_ids])
                                                                 .where(applicable_filters)
                                                                 .where("provider_data->>'id' in(?)", resource_urls)
                                                                 .ignored_from_categories(IGNORE_CATEGORY_UNOPTIMIZED)
                                                                 .find_with_tags(filters[:tenant_tags], 'OR') # applying tenant tags
                                                                 .find_with_tags(tags, filters[:tag_operator])
    provider_ids = response_resources.pluck("provider_data->>'id'")
    subscription_id = Adapter.where(id: filters[:adapter_id]).map(&:subscription_id)
    conditions = {
                  :subscription_id.in => subscription_id,
                  :region_id.in => filters[:region_id],
                  :provider_id.in => provider_ids
                 }
    Azure::Rightsizing.vm.where(conditions)
  end
  
  def self.fetch_unused_ignored_services(resource_urls, filters, tags)
    applicable_filters = filters.slice(:adapter_id, :region_id, :azure_resource_group_id).as_json
    Azure::Resource.filter_resource_group(filters[:tenant_resource_group_ids])
                   .where(applicable_filters)
                   .where("provider_data->>'id' in(?)", resource_urls)
                   .ignored_from_categories(IGNORE_CATEGORY_UNUSED)
                   .find_with_tags(filters[:tenant_tags], 'OR') # applying tenant tags
                   .find_with_tags(tags, filters[:tag_operator])
  end

  def self.ignored_rightsized_vms_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
    ignored_rightsized_vms = fetch_unoptmized_ignored_vms(resource_urls, filters, tags)
    formatted_rightsized_vms = format_unoptimized_ignore_resources(ignored_rightsized_vms, filters, current_tenant_currency_rate[0])
    representer = ServiceAdviser::Azure::Csv::VirtualMachinesRightsizingSummaryRepresenter
    formatted_rightsized_vms = serialize_unoptimized_services(formatted_rightsized_vms, account, tenant, representer, current_tenant_currency_rate)
    formatted_rightsized_vms['virtual_machines_rightsizings']
  end

  def self.format_unused_ignore_resources(ignored_resources, filters, current_tenant_currency_rate)
    # ignored_resources = add_additional_informations(ignored_resources)
    response_resources = { total_service_count: ignored_resources.count, services: ignored_resources }
    # do paginate here
    # add comment count and ignored from
    # response_resources = response_resources.extend(ServiceAdviser::Azure::ListServiceTypeWithDetailRepresenter)
    # JSON.parse(response_resources.to_json, object_class: ServiceAdviser::OpenStructTableRemove).as_json
    options = {
      user_options: {
        currency_code: current_tenant_currency_rate[0],
        currency_rate: current_tenant_currency_rate[1]
      }
    }
    response_resources = response_resources.extend(ServiceAdviser::Azure::Csv::ListServiceTypeWithDetailRepresenter)
    response_resources = response_resources.to_json(options)
    JSON.parse(response_resources, object_class: ServiceAdviser::OpenStructTableRemove).as_json
  end

  def self.format_unoptimized_ignore_resources(ignored_resources, filters, current_tenant_currency_code)
    options = {
      adapter_id: filters[:adapter_id],
      region_id: filters[:region_id]
    } 
    Rightsizings::RightSizingService.format_response(ignored_resources, options, current_tenant_currency_code)
  end

  def self.serialize_unoptimized_services(formatted_rightsized_resources, account, tenant, representer, current_tenant_currency_rate)
    resources = formatted_rightsized_resources[0]
    meta = formatted_rightsized_resources[1]
    options = { 
                user_options: { 
                                current_account: account,
                                current_tenant: tenant,
                                currency_code: current_tenant_currency_rate[0],
                                currency_rate: current_tenant_currency_rate[1]
                              },
                total_records: meta
              }
    resources = resources.extend(representer)
    resources = resources.to_json(options)
    JSON.parse(resources, object_class: ServiceAdviser::OpenStructTableRemove).as_json
  end

  def self.ignore_services_count_response(ignored_resources, current_tenant_currency_rates)
    ignored_resources.map do |category, services|
      count = services.count
      cost_sum =  services.inject(0) do |sum, service|
        cost = if category.eql?(:unused)
                 service.try(:cost_by_hour) * 24 * 30 * current_tenant_currency_rates[1] rescue 0.0
               else
                 service.try(:costsavedpermonth) * current_tenant_currency_rates[1]
               end
        sum + cost
      end
      { count: count, service_cost_sum: cost_sum, category: category, currency: current_tenant_currency_rates[0] }
    end
  end

  def self.ignore_services_details_response(params, ignored_resources, current_tenant_currency_rate)
    ignored_resources[:services]
    ignored_resources[:services] = ignored_resources[:services].paginate(page: params[:page], per_page: params[:per_page]) if params[:page].present? && params[:per_page].present?
    ignored_resources[:services].each do |obj|
      provider_id = obj['azure_resource_url'] || obj['provider_id']
      service_details = ServiceDetail.where(adapter_id: obj['adapter_id'],
                                            region_id: obj['region_id'],
                                            provider_id: provider_id)
                                     .order('commented_date DESC')
      obj['comment_count'] = service_details.count
      obj['ignore_till'] = ServiceAdviser::Base.format_ignore_till(service_details.comment_type_ignored.first)
    end
    ignored_resources
  end

  def self.update_service_association_ingored_from(filters, _ignored_from_category, _ignored_from)
    azure_resource = Azure::Resource.where(filters.except(:provider_id))
                                    .where("provider_data->>'id'=?", filters[:provider_id])
                                    .try(:first)
    return unless azure_resource.present?

    azure_resource.ignored_from = ['un-ignored']
    azure_resource.save!
    ServiceAdviser::Base.delete_scheduled_un_ignore_job(azure_resource.id)
  end

  def self.format_sort(sort, _service_type)
    split_sort = sort.split(' ')
    return sort if split_sort[0].eql?('cost_by_hour')

    return "provider_data->>'time_created' #{split_sort[1]}" if split_sort[0].eql?('time_created_at')
  end

  # Common method to filter services by tenant tags or by applied tags.
  def self.filter_services_by_tags(query, filter_tags, tags, tag_operator)
    if filter_tags.blank?
      tags.map { |s| s["tag_value"] = nil if s["tag_value"].eql? "" }
      services = query.find_with_tags(tags, tag_operator)
    else
      filter_tags = (filter_tags + tags).uniq { |h| h["tag_key"] } unless tags.blank?
      filter_tags.map { |s| s["tag_value"] = nil if s["tag_value"].eql? "" }
      services = query.find_with_tags(filter_tags, tag_operator)
    end
  end

  def self.fetch_unoptmized_ignored_sqldbs(resource_urls, filters, tags)
    applicable_filters = filters.slice(:adapter_id, :region_id, :azure_resource_group_id).as_json
    response_resources = Azure::Resource::Database::SQL::DB.filter_resource_group(filters[:tenant_resource_group_ids])
                                                                 .where(applicable_filters)
                                                                 .where("provider_data->>'id' in(?)", resource_urls)
                                                                 .ignored_from_categories(IGNORE_CATEGORY_UNOPTIMIZED)
                                                                 .find_with_tags(filters[:tenant_tags], 'OR') # applying tenant tags
                                                                 .find_with_tags(tags, filters[:tag_operator])
    provider_ids = response_resources.pluck("provider_data->>'id'")
    subscription_id = Adapter.where(id: filters[:adapter_id]).map(&:subscription_id)
    conditions = {
                  :subscription_id.in => subscription_id,
                  :region_id.in => filters[:region_id],
                  :provider_id.in => provider_ids
                 }
    Azure::Rightsizing.sqldb.where(conditions)
  end

  def self.ignored_rightsized_sqldbs_details(resource_urls, filters, tags, account, tenant, current_tenant_currency_rate)
    ignored_rightsized_sqldbs = fetch_unoptmized_ignored_sqldbs(resource_urls, filters, tags)
    options = { adapter_id: filters[:adapter_id], region_id: filters[:region_id] }
    formatted_rightsized_sqldbs = Rightsizings::RightSizingService.format_db_response(ignored_rightsized_sqldbs, options, current_tenant_currency_rate[0])
    representer = ServiceAdviser::Azure::SQLDBRightsizingSummaryRepresenter
    formatted_rightsized_sqldbs = serialize_unoptimized_services(formatted_rightsized_sqldbs, account, tenant, representer, current_tenant_currency_rate)
    formatted_rightsized_sqldbs['sql_db_rightsizings']
  end

end
