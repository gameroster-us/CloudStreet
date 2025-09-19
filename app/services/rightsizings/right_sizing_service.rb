class Rightsizings::RightSizingService < ApplicationService

  class << self

    def get_right_sized_instances(params, current_account, current_tenant, current_tenant_currency_rate, &block)
      params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::AWS', params[:adapter_id])
      region = get_selected_region(params[:region_id]) unless params[:region_id].blank?
      klass = get_ec2_right_size_class_name(current_account)
      exclude_ec2_instances_ids = exclude_ec2_instances(current_account, current_tenant, params[:adapter_id])
      right_sized_instances = if exclude_ec2_instances_ids.present?
                                klass.not_in(:instanceid.in => exclude_ec2_instances_ids).get_right_sized_instances(params, region, current_account.id).pluck(:instanceid)
                              else
                                klass.all.get_right_sized_instances(params, region, current_account.id).pluck(:instanceid)
                              end

      ri_instances = get_service_filtered_instances(right_sized_instances, current_account, current_tenant, params, klass, current_tenant_currency_rate)
      return ri_instances if params[:from_recommendation_worker]
      total_saving = ri_instances.sum { |col| col['costsavedpermonth'] }.round(2)
      meta = { meta_data: { total_saving: total_saving, instance_count: ri_instances.count, currency: current_tenant_currency_rate[0], currency_rate: current_tenant_currency_rate[1], klass: klass.to_s } }
      ri_instances = ri_instances.paginate(page: params[:page], per_page: params[:limit]) if ri_instances.present? && params[:page].present? && params[:limit].present?
      ri_instances = add_comment_count(ri_instances, params, 'AWS')
      ri_instances = ServiceAdviser::Base.sort_idle_services(ri_instances,"costsavedpermonth #{params["sort"] || 'DESC'}",nil)
      status Status, :success, [ri_instances, meta], &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def adapter_wise_rightsizing(current_account, current_tenant, params, current_tenant_currency_rate, &block)
      adapters = if params[:adapter_name].present?
                   current_tenant.adapters.right_sizing_adapters.name_like(params[:adapter_name])
                 else
                   current_tenant.adapters.right_sizing_adapters
                 end
      params[:adapter_id] = adapters.ids
      region = get_selected_region(params[:region_id]) unless params[:region_id].blank?
      klass = get_ec2_right_size_class_name(current_account)
      exclude_ec2_instances_ids = exclude_ec2_instances(current_account, current_tenant, params[:adapter_id])
      right_sized_instances = if exclude_ec2_instances_ids.present?
                                klass.not_in(:instanceid.in => exclude_ec2_instances_ids).get_right_sized_instances(params, region, current_account.id).pluck(:instanceid)
                              else
                                klass.all.get_right_sized_instances(params, region, current_account.id).pluck(:instanceid)
                              end

      right_sized_instances = get_service_filtered_instances(right_sized_instances, current_account, current_tenant, params, klass, current_tenant_currency_rate)
      savings = right_sized_instances.group_by(&:Account).inject({}) do |m, (k, v)|
        m.merge(k => v.sum(&:costsavedpermonth))
      end
      no_of_instance = right_sized_instances.group_by(&:Account).inject({}) do |m, (k, v)|
        m.merge(k => v.count)
      end
      results = adapters.pluck(:id, :name, :data).map do |adapter_id, adapter_name, adapter_data|
        { adapter_id: adapter_id, adapter_name: adapter_name, potential_saving: savings[adapter_data['aws_account_id']].to_f, no_of_instance: no_of_instance[adapter_data['aws_account_id']] || 0 }
      end
      all_adapters_saving = results.inject(0) { |sum, r| sum += r[:potential_saving] ; sum }
      all_right_sized_instance_count = results.inject(0) { |sum, r| sum += r[:no_of_instance] ; sum }
      response = {adapters: results, total_potential_saving: all_adapters_saving, all_right_sized_instance_count: all_right_sized_instance_count}
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def get_selected_region(region_id)
      if region_id.blank?
        ''
      else
        selected_region = Region.find(region_id)
        region = CommonConstants::REGION_CODES.key(selected_region.region_name).to_s
      end
    end

    def to_csv(result, account, current_tenant_currency_rate)
      res = result.first
      attributes = { aws_account_id: 'AWS Account Id', account: 'Account', instance_name: "Service Name", service_type: 'Service Type', instanceid: "Service ID", region: "Region", instancetype: "Instance Size", resizetype: "Recommended Size", costsavedpermonth: "MES", custom_resize_type: 'Custom Recommended Size', custom_costsavedpermonth: 'Custom MES', instancetags: "Tags", lifecycle: "Lifecycle", task_status: 'Task Status',
        maxcpu: 'Max Cpu', maxmem: 'Max Memory', maxnetwork: 'Max Network', maxiops: 'Max Disk IO'
      }
      account_show_default_recommendation = account.service_adviser_configs.aws_rightsized_ec2_default_config.show_default_recommendation rescue true
      # Remove default recommendation column(Recommended Size) when show_default_recommendation false
      unless account_show_default_recommendation
         attributes.delete(:resizetype)
         attributes.delete(:costsavedpermonth)
      end
      csv = CSV.generate(headers: true) do |csv|
        csv << attributes.values
        res.each do |record|
          service = Service.find_by_provider_id(record.instanceid)
          if account_show_default_recommendation
            dynamic_record = record
            custom_recommendation = EC2RightSizingExtendResult.where(instanceid: record.instanceid, account_id: account.id).first
            resizetype = custom_recommendation.present? ? custom_recommendation.try(:resizetype) : 'N/A'
            custom_costsavedpermonth = custom_recommendation.present? ? custom_recommendation.try(:costsavedpermonth).to_f * current_tenant_currency_rate[1] : 'N/A'
          else
            resizetype = record.resizetype
            custom_costsavedpermonth = record.costsavedpermonth
            dynamic_record = EC2RightSizing.where(instanceid: record.instanceid, Account: record.Account).first
          end
          csv << attributes.keys.map do |attr|
            if attr == :instance_name
              dynamic_record.instancetags.split("|").map { |t| t.strip[/^Name\S[^|]*/] }.compact[0].split(':').last rescue ''
            elsif attr == :costsavedpermonth
              dynamic_record.send(attr).to_f
            elsif attr == :region
              CommonConstants::REGION_CODES[dynamic_record.region.to_sym] rescue ''
            elsif attr == :lifecycle
              if service.provider_data['lifecycle'].eql?('spot')
                'spot'
              else
                'normal'
              end
            elsif attr.eql?(:instancetags)
              ServiceAdviser::Base.format_tags_str_to_hash(dynamic_record.instancetags)
            elsif attr.eql?(:custom_resize_type)
              resizetype
            elsif attr.eql?(:custom_costsavedpermonth)
              custom_costsavedpermonth
            elsif attr.eql?(:account)
              service&.adapter.name
            elsif attr.eql?(:aws_account_id)
              service&.adapter.aws_account_id
            elsif attr.eql?(:service_type)
              'EC2'
            elsif attr.eql?(:task_status)
              SaRecommendation.find_by(provider_id: service.provider_id)&.state&.capitalize || 'N/A'
            else
              dynamic_record.send(attr)
            end
          end
        end
      end
      csv
    end

    def get_service_filtered_instances(right_sized_instance_ids, current_account, current_tenant, params={}, klass, current_tenant_currency_rate)
      return [] unless right_sized_instance_ids.any?

      instances = if params.key?(:lifecycle) && params[:lifecycle].present?
                    if params[:lifecycle].downcase.eql?("spot")
                      Service.instance_servers.active_services.where(adapter_id: params[:adapter_id], provider_id: right_sized_instance_ids)
                        .where.not("ignored_from && ARRAY['ec2_right_sizings', 'all']::varchar[]").spot_instances
                    else
                      Service.instance_servers.active_services.where(adapter_id: params[:adapter_id], provider_id: right_sized_instance_ids)
                        .where.not("ignored_from && ARRAY['ec2_right_sizings', 'all']::varchar[]").normal_lifecycle_instances
                    end
                  else
                    Service.instance_servers.active_services.where(adapter_id: params[:adapter_id], provider_id: right_sized_instance_ids)
                      .where.not("ignored_from && ARRAY['ec2_right_sizings', 'all']::varchar[]")
                  end

      tags = JSON.parse(params["tags"]) rescue []
      tag_operator = params['tag_operator'].present? ? params['tag_operator'] : "OR"
    
      unless current_tenant.tags.empty?
        filter_tags = [current_tenant.tags]
        instances = instances.find_with_tags(filter_tags, tag_operator, current_account)
      end

      instance_ids =  if tags.any?
                        instances.find_with_tags(tags, tag_operator, current_account).pluck(:provider_id)
                      else
                        instances.pluck(:provider_id)
                      end
      return [] unless instance_ids.any?

      order_by = params["sort"] || 'DESC'
      if klass.to_s.eql?('EC2RightSizingExtendResult')
        right_sized_instances = klass.in(ec2_right_size_id: EC2RightSizing.in(instanceid: instance_ids).map{|a| a.id.to_s}, account_id: current_account.id).order_by(costsavedpermonth: order_by.to_s.to_sym)
      else
        right_sized_instances = klass.in(instanceid: instance_ids).order_by(costsavedpermonth: order_by.to_s.to_sym)
      end
      # return right_sized_instances if params[:from_recommendation_worker]
      # filters = {
      #   provider_type: 'aws',
      #   category: 'unoptimized',
      #   service_type: 'ec2'
      # }
      # configuration = current_account.service_adviser_configs.find_by(filters)
      # if configuration.show_default_recommendation.eql?(false)
      #   right_sized_instances = right_sized_instances.select{|instance| instance if EC2RightSizingExtendResult.where(instanceid: instance.instanceid, account_id: current_account.id).first.present? }
      # end
     right_sized_instances.map {|right_sized_instance| right_sized_instance.costsavedpermonth *= current_tenant_currency_rate[1] ; right_sized_instance }
    end

    def exclude_ec2_instances(current_account, current_tenant, adapter_ids)
      region_ids = current_account.get_enabled_regions("AWS").pluck(:id)
      # adapter_ids = current_tenant.adapters.normal_adapters.available.aws_adapter.ids
      # config_check = ServiceAdviserConfiguration.find_by(account_id: current_account.id)
      # stopped_ec2_check = config_check.stopped_rightsizing_config_check
      # running_ec2_check = config_check.running_rightsizing_config_check
      config_check = current_account.service_adviser_configs.unoptimized_category.find_by(service_type: 'ec2')
      stopped_ec2_check = config_check.stopped_rightsizing_config_check
      running_ec2_check = config_check.running_rightsizing_config_check
      stopped_ec2_provider_ids = Services::Compute::Server::AWS.active_services.where(adapter_id: adapter_ids, region_id: region_ids, idle_instance: true, state: ["stopped"]).pluck(:provider_id)
      stopped_ec2_provider_ids = stopped_ec2_check ? [] : stopped_ec2_provider_ids
      running_ec2_provider_ids = Services::Compute::Server::AWS.active_services.where(adapter_id: adapter_ids, region_id: region_ids, idle_instance: true, state: ["running"]).pluck(:provider_id)
      running_ec2_provider_ids = running_ec2_check ? [] : running_ec2_provider_ids
      provider_ids = (running_ec2_provider_ids + stopped_ec2_provider_ids).compact.flatten
    end

    def get_right_sized_vms(params, current_account, current_tenant, current_tenant_currency_rate, &block)
      params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::Azure', params[:adapter_id])
      params[:region_id] = if params[:region_id].blank?
                            current_account.get_enabled_regions_ids(:azure)
                            else
                              Array[*params[:region_id]]
                            end
      order_by = params["sort"] || 'DESC'
      active_right_sizing_vms = Azure::Rightsizing.get_right_sized_vms(params)

      running_vm_size_hash = get_filtered_right_sized_vms(params, current_account, current_tenant, active_right_sizing_vms)
      right_sized_vms = active_right_sizing_vms.where(:provider_id.in => running_vm_size_hash.keys)
                                               .order_by(costsavedpermonth: "#{order_by}".to_sym)
      return right_sized_vms if params[:from_recommendation_worker]

      right_sized_vms.select! { |rightsize_vm| rightsize_vm.instancetype.eql? running_vm_size_hash[rightsize_vm.provider_id] }
      right_sized_vms_with_currency_converted = convert_into_current_tenant_currency(right_sized_vms, current_tenant_currency_rate)
      return right_sized_vms_with_currency_converted unless block_given?

      response = format_response(right_sized_vms_with_currency_converted, params, current_tenant_currency_rate[0])
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def format_response(right_sized_vms, params, current_tenant_currency_code)
      vm_count = right_sized_vms.count
      total_saving = right_sized_vms.pluck('costsavedpermonth')&.sum.round(2)
      meta = { meta_data: { total_saving: total_saving, vm_count: vm_count, currency: current_tenant_currency_code } }
      right_sized_vms = right_sized_vms.paginate(page: params[:page], per_page: params[:limit]) if right_sized_vms.present? && params[:page].present? && params[:limit].present?
      right_sized_vms = add_comment_count(right_sized_vms, params, 'Azure')
      [right_sized_vms, meta]
    end

    def format_db_response(right_sized_sql_dbs, params, current_tenant_currency_code)
      sql_db_count = right_sized_sql_dbs.count
      total_saving = right_sized_sql_dbs.pluck('costsavedpermonth')&.sum.round(2)
      meta = { meta_data: { total_saving: total_saving, sql_db_count: sql_db_count, currency: current_tenant_currency_code } }
      right_sized_sql_dbs = right_sized_sql_dbs.paginate(page: params[:page], per_page: params[:limit]) if right_sized_sql_dbs.present? && params[:page].present? && params[:limit].present?
      right_sized_sql_dbs = add_comment_count(right_sized_sql_dbs, params, 'Azure')
      [right_sized_sql_dbs, meta]
    end
    
    def get_filtered_right_sized_vms(params, current_account, current_tenant, right_sized_vms)
      provider_ids = right_sized_vms.pluck(:provider_id)
      tags = JSON.parse(params["tags"]) rescue []
      tag_operator = params["tag_operator"].present? ? params["tag_operator"] : "OR"
      query = Azure::Resource::Compute::VirtualMachine.where(adapter_id: params[:adapter_id], region_id: params[:region_id])
                                                      .active.running_vm
                                                      .exclude_aks_resource_group_services
                                                      .exclude_databricks_resource_group_services
                                                      .where("provider_data->>'id' IN(?)", provider_ids)
                                                      .not_ignored_from(['vm_right_sizings'])
      unless params[:azure_resource_group_id].present?
        query = query.filter_resource_group(current_tenant.azure_resource_group_ids)
      else
        query = query.where(azure_resource_group_id: params[:azure_resource_group_id])
      end
      unless current_tenant.tags.blank?
        filter_tags = [current_tenant.tags]
        query = query.find_with_tags(filter_tags, tag_operator, current_account)
      end
      query = query.find_with_tags(tags, tag_operator, current_account) if tags.present? 
      #query.pluck(Arel.sql("provider_data->'id', data->'vm_size'")).to_h rescue {}
      query.pluck("provider_data->>'id'", "data->>'vm_size'").to_h rescue {}
    end

    def get_filtered_right_sized_sql_dbs(params, current_account, current_tenant, right_sized_sql_dbs)
      provider_ids = right_sized_sql_dbs.pluck(:provider_id)
      tags = JSON.parse(params["tags"]) rescue []
      tag_operator = params["tag_operator"].present? ? params["tag_operator"] : "OR"
      query = Azure::Resource::Database::SQL::DB.where(adapter_id: params[:adapter_id], region_id: params[:region_id])
                                                      .active.only_running
                                                      .exclude_aks_resource_group_services
                                                      .exclude_databricks_resource_group_services
                                                      .where("provider_data->>'id' IN(?)", provider_ids)
                                                      .not_ignored_from(['sqldb_right_sizings'])
      unless params[:azure_resource_group_id].present?
        query = query.filter_resource_group(current_tenant.azure_resource_group_ids)
      else
        query = query.where(azure_resource_group_id: params[:azure_resource_group_id])
      end
      unless current_tenant.tags.blank?
        filter_tags = [current_tenant.tags]
        query = query.find_with_tags(filter_tags, tag_operator, current_account)
      end
      query = query.find_with_tags(tags, tag_operator, current_account) if tags.present? 
      running_sql_db_and_name = query.pluck("provider_data->>'id'", "data->>'requested_service_objective_name'").to_h rescue []
    end

    def adapter_wise_vm_right_sizing(current_account, current_tenant, params, current_tenant_currency_rate, &block)
      params[:adapter_id] = 'all'
      adapters = if params[:adapter_name].present?
                  current_tenant.adapters.azure_adapter.normal_adapters.available.name_like(params[:adapter_name])
                 else
                  current_tenant.adapters.azure_adapter.normal_adapters.available
                 end
      params[:adapter_id] = adapters.ids
      right_sized_vms = get_right_sized_vms(params, current_account, current_tenant, current_tenant_currency_rate) || []
      savings = {}
      counts = {}
      right_sized_vms.group_by(&:subscription_id).each do |k, v|
        savings.merge!(k => v.pluck(:costsavedpermonth)&.sum)
        counts.merge!(k => v.count)
      end

      results = adapters.map do |a|
        {
          adapter_id: a.id,
          adapter_name: a.name,
          potential_saving: savings[a.subscription_id].to_f,
          no_of_instance: counts[a.subscription_id] || 0
        }
      end
      total_saving = savings.values.sum rescue 0.0
      total_count = counts.values.sum rescue 0
      response = {
        adapters: results || [],
        total_potential_saving: total_saving,
        all_right_sized_instance_count: total_count
      }
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def adapter_wise_sqldb_right_sizing(current_account, current_tenant, params, current_tenant_currency_rate, &block)
      params[:adapter_id] = 'all'
      adapters = if params[:adapter_name].present?
                  current_tenant.adapters.azure_adapter.normal_adapters.available.name_like(params[:adapter_name])
                 else
                  current_tenant.adapters.azure_adapter.normal_adapters.available
                 end
      params[:adapter_id] = adapters.ids
      right_sized_sql_dbs = get_right_sized_sqldbs(params, current_account, current_tenant, current_tenant_currency_rate) || []
      savings = {}
      counts = {}
      right_sized_sql_dbs.group_by(&:subscription_id).each do |k, v|
        savings.merge!(k => v.pluck(:costsavedpermonth)&.sum)
        counts.merge!(k => v.count)
      end

      results = adapters.map do |a|
        {
          adapter_id: a.id,
          adapter_name: a.name,
          potential_saving: savings[a.subscription_id].to_f,
          no_of_instance: counts[a.subscription_id] || 0
        }
      end
      total_saving = savings.values.sum rescue 0.0
      total_count = counts.values.sum rescue 0
      response = {
        adapters: results || [],
        total_potential_saving: total_saving,
        all_right_sized_instance_count: total_count
      }
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def right_sized_vms_csv(res, tenant)
      attributes = ['Resource Name',
                    'Subscription Id',
                    'Subscription Name',
                    'Region',
                    'Resource Group',
                    'VM Size',
                    'vCPU',
                    'Memory',
                    'Recommended Size',
                    'Recommended vCPU',
                    'Recommended Memory',
                    'Tags',
                    'Task Status',
                    'MES',
                    'Max Cpu',
                    'Max Memory'
                   ]
      csv_records = res.pluck(:id, :name, :subscription_id, :subscription_name, :region_name,
                              :resource_group, :instancetype, :vcpu,
                              :memory, :resizetype,
                              :newvcpu, :newmemory,
                              :instancetags, :provider_id, :costsavedpermonth,
                              :maxcpu, :maxmem)
      is_csp_mapping = res.pluck(:id, :additional_properties).to_h.transform_keys!(&:to_s)
      csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        csv_records.each do |rec|
          rec[-4] = SaRecommendation.find_by(provider_id: rec[-4])&.state&.capitalize || 'N/A'
          rec[-3] = 'N/A' if is_csp_mapping[rec[0].to_s].try(:[], 'is_csp')
          rec[3] =  tenant.adapters.azure_normal_active_adapters.where("data->'subscription_id'=?", rec[2]).first&.subscription.try(:display_name)
          csv << rec[1..-1] # exclude the 0th position as it contains the ID
        end
      end
      csv
    end

    def get_right_sized_sqldbs(params, current_account, current_tenant, current_tenant_currency_rate, &block)
      params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::Azure', params[:adapter_id])
      params[:region_id] = if params[:region_id].blank?
                            current_account.get_enabled_regions_ids(:azure)
                            else
                              Array[*params[:region_id]]
                            end
      order_by = params["sort"] || 'DESC'
      active_right_sizing_sql_dbs = Azure::Rightsizing.get_right_sized_sql_dbs(params)
      running_sql_db_size_hash = get_filtered_right_sized_sql_dbs(params, current_account, current_tenant, active_right_sizing_sql_dbs)
      right_sized_sql_dbs =  active_right_sizing_sql_dbs.where(:provider_id.in => running_sql_db_size_hash.keys)
                                               .order_by(costsavedpermonth: "#{order_by}".to_sym)

      return right_sized_sql_dbs if params[:from_recommendation_worker]

      right_sized_sql_dbs.select! { |rightsize_db| rightsize_db.instancetype.eql? running_sql_db_size_hash[rightsize_db.provider_id] }
      right_sized_sql_dbs_with_currency_converted = convert_into_current_tenant_currency(right_sized_sql_dbs, current_tenant_currency_rate)

      return right_sized_sql_dbs_with_currency_converted unless block_given?

      response = format_db_response(right_sized_sql_dbs_with_currency_converted, params, current_tenant_currency_rate[0])
      status Status, :success, response, &block
    rescue StandardError => e
      status Status, :error, e, &block
    end

    def right_sized_sqldbs_csv(res, current_organisation)
      adapter_map = current_organisation.adapters.azure_adapter.each_with_object({}) { |adapter, memo| memo[adapter.subscription_id] = adapter.slice(:name) }
      attributes = ['Resource Name',
                    'Subscription Id',
                    'Subscription Name',
                    'Region',
                    'Resource Group',
                    'Instance Type',
                    'Resize Type',
                    'Tags',
                    'MES'
                   ]
      csv_records = res.pluck(:name, :subscription_id, :subscription_name, :region_name, :resource_group,
                              :instancetype, :resizetype,
                              :instancetags, :costsavedpermonth)

      csv = CSV.generate(headers: true) do |csv|
        csv << attributes
        csv_records.each do |rec|
          rec[2] = adapter_map[rec[1]]['name'] || 'N/A'
          csv << rec
        end
      end
      csv 
    end

    def add_comment_count(instances, params, provider_type)
      filters = params.slice(:adapter_id, :region_id)
      filters.delete(:region_id) unless params[:region_id].present?
      filters.merge!(provider_type: provider_type)
      # optmize n+1 query
      provider_ids = instances.map { |instance| instance.try(:provider_id) || instance.try(:instanceid) || instance.try(:key) }
      filters.merge!(provider_id: provider_ids)
      service_detail_res = ServiceDetail.where(filters.as_json).group(:provider_id).count
      instances.each do |rightsize_instance|
        provider_id = rightsize_instance.try(:provider_id) || rightsize_instance.try(:instanceid) || rightsize_instance.try(:key)
        rightsize_instance.comment_count = service_detail_res[provider_id] || 0
      end
    end

    def convert_into_current_tenant_currency(resources, current_tenant_currency_rate)
      resources.map do |resource|
        resource.costsavedpermonth = resource.costsavedpermonth * current_tenant_currency_rate[1]
        resource
      end
    end

    def get_ec2_right_size_class_name(current_account)
      show_default_recommendation = current_account.service_adviser_configs.aws_rightsized_ec2_default_config.show_default_recommendation rescue true
      show_default_recommendation ? 'EC2RightSizing'.constantize : 'EC2RightSizingExtendResult'.constantize
    end
  end

end
