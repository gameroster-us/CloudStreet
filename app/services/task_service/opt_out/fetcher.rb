# frozen_string_literal: true

# Opt out details fetcher
class TaskService::OptOut::Fetcher < CloudStreetService
  class << self
    ## Code for filter service tags from out-out data
    def get_opts_out_service_tags(account, params)
      task = fetch Task, params['task_id']
      if params['dry_run'].present? && params['dry_run'].eql?('true')
        return {} unless task.account_id == account.id

        data = get_task_services(task, 'service_tags')
        key_pairs = data.group_by { |d| d['service_type'] }.each_with_object({}) do |(key, value), memo|
          memo.merge!({ key => value.map { |m| m['tags'] if m['tags'].present? }.compact.flatten })
        end
        all_data = key_pairs.each_with_object({}) do |(key, value), memo|
          memo.merge!({ key => value.group_by { |h| h['tag_key'] }.transform_values do |values|
            values.uniq.map { |v| v['tag_value'] }
          end })
        end
      else
        key_pairs = EventNotificationData.not_in(service_type: [nil]).where(account_id: account.id, task_id: params[:task_id]).group_by(&:service_type).each_with_object({}) { |(key, value), memo| memo.merge!({ key => value.map { |m| m.try(:tags) if m.try(:tags).present? }.compact.flatten }) }
        tag_values = key_pairs.each_with_object({}) { |(key, value), memo| memo.merge!({ key => value.group_by { |h| h['tag_key'] }.transform_values { |values| values.uniq.map { |v| v['tag_value'] } } }) }
      end
    end

    ## Code for filter adapters from out-out data
    def get_opts_out_adapters(account, params)
      task = fetch Task, params['task_id']
      if params['dry_run'].present? && params['dry_run'].eql?('true')
        task.account_id == account.id ? get_task_services(task, 'adapter') : []
      else
        EventNotificationData.not_in(service_type: [nil]).where(account_id: account.id, task_id: params[:task_id]).each_with_object([]) { |s, memo| memo << { adapter_id: s.try(:adapter_id), adapter_name: s.try(:adapter_name) } if s.try(:adapter_id).present? }.uniq
      end
    end

    ## Code to filter region from opt-out data
    def get_opts_out_regions(account, params)
      task = fetch Task, params['task_id']
      if params['dry_run'].present? && params['dry_run'].eql?('true') && !task.provider.eql?('VmWare')
        task.account_id == account.id ? get_task_services(task, 'region') : []
      else
        EventNotificationData.not_in(service_type: [nil]).where(account_id: account.id, task_id: params[:task_id]).each_with_object([]) { |s, memo| memo << { region_id: s.try(:region_id), region_name: s.try(:region) } if s.try(:region_id).present? }.uniq
      end
    end

    ## Code to filter service types from opt-out data
    def get_opts_out_service_types(account, params)
      task = fetch Task, params['task_id']
      if params['dry_run'].present? && params['dry_run'].eql?('true')
        task.account_id == account.id ? get_task_services(task, 'service_type') : []
      else
        EventNotificationData.not_in(service_type: [nil]).where(account_id: account.id, task_id: params[:task_id]).each_with_object([]) { |s, memo| memo << s.try(:service_type) if s.try(:service_type).present? }.uniq
      end
    end

    ## Code to filter resource groups for azure task from opt-out data
    def get_opts_out_resource_groups(account, params)
      task = fetch Task, params['task_id']
      if params['dry_run'].present? && params['dry_run'].eql?('true')
        task.account_id == account.id ? get_task_services(task, 'resource_group') : []
      else
        EventNotificationData.not_in(service_type: [nil]).where(account_id: account.id, task_id: params[:task_id]).each_with_object([]) { |s, memo| memo << { resource_group_id: s.try(:resource_group_id), resource_group: s.try(:resource_group) } if s.try(:resource_group_id).present? }.uniq
      end
    end

    ## Code for display list of out out data
    def get_opt_out_data(account, task_params, &block)
      task = fetch Task, task_params['task_id']
      if task.nil?
        status Status, :error, "Couldn't find Task with id #{task_params['task_id']}", &block
        return nil
      end
      # This is when the task is run by dry run
      if task_params['dry_run'].present? && task_params['dry_run'].eql?('true')
        fetch_opt_out_services, total_records, total_savings, custom_email = get_task_services_with_filters(account, task, task_params)
        status Status, :success, [fetch_opt_out_services, task.task_type, total_records, total_savings, custom_email], &block
      elsif task.can_update_opt_out_data?(task_params, task)
        fetch_opt_out_services = EventNotificationData.where(task_id: task_params['task_id'])
        fetch_opt_out_services = fetch_opt_out_services.where(service_type: task_params['service_type']) if task_params['service_type'].present?
        fetch_opt_out_services = fetch_opt_out_services.where(adapter_id: task_params['adapter_id']) if task_params['adapter_id'].present?
        fetch_opt_out_services = fetch_opt_out_services.where(region: task_params['region']) if task_params['region'].present?
        fetch_opt_out_services = fetch_opt_out_services.where(resource_group_id: task_params['azure_resource_group_id']) if task_params['azure_resource_group_id'].present? && task.type.eql?('Task::Azure')
        tags = JSON.parse(task_params['tags'] || '[]')
        if tags.present?
          tag_key = tags['tag_key']
          tag_value = tags['tag_value']
          tag_sign = tags['tag_sign']
          if tag_sign.eql?('=') && tag_value.present? && tag_key.present?
            fetch_opt_out_services = fetch_opt_out_services.where(tags: { tag_key: tag_key, tag_value: tag_value })
          elsif tag_value.present? && tag_key.present?
            fetch_opt_out_services = fetch_opt_out_services.where('tags.tag_key' => tag_key, 'tags.tag_value' => { '$ne' => tag_value })
          end
        end

        sort_by = task_params['sort_by'].present? ? task_params['sort_by'] : 'desc'

        if task_params['email'] == 'all'
          fetch_opt_out_services = fetch_opt_out_services.order_by(monthly_estimated_cost: :"#{sort_by}")
        else
          mail = URI.unescape(task_params['email'])
          fetch_opt_out_services = fetch_opt_out_services.order_by(monthly_estimated_cost: :"#{sort_by}").select { |a| (a.notify_to_tag_name.present? && a.notify_to_tag_name[task.notify_to_tag_name] && a.notify_to_tag_name[task.notify_to_tag_name] == mail) }
        end

        total_savings = total_monthly_estimated_savings(fetch_opt_out_services.as_json) unless task.provider.eql?('VmWare')

        fetch_opt_out_services, total_records = data_pagination(fetch_opt_out_services.as_json, task_params)
        status Status, :success, [fetch_opt_out_services, task.task_type, total_records, total_savings, custom_email_data(task)], &block
      else
        status Status, :validation_error, task.errors.messages, &block
      end
    end

    def total_monthly_estimated_savings(fetch_opt_out_services)
      return format('%<number>.2f', number: 0) unless fetch_opt_out_services.present?

      sum = 0
      fetch_opt_out_services.each { |service| sum += service.stringify_keys['monthly_estimated_cost'] }
      format('%<number>.2f', number: sum.round(2))
    end

    def get_task_services(task, filter_name = false)
      all_data = []
      service_types = provider_service_types(task)
      service_types.each do |service_type|
        services = if task.provider.eql?('AWS')
                     %w[services snapshots].include?(service_type) ? task.send(service_type) : MachineImage.where(id: task.machine_image_ids)
                   else
                     task.send(service_type)
                   end
        services.each do |service|
          rec = {}
          if filter_name.present? # this is when the filter api is invoked acoordingly the filter name is pass
            case filter_name
            when 'adapter'
              if task.provider.eql?('VmWare')
                rec['adapter_id'] = service.vw_vcenter.adapter_id
                rec['adapter_name'] = service.inventory_adapter.name
              else
                rec['adapter_id'] = service.try(:adapter).try(:id)
                rec['adapter_name'] = service.try(:adapter).try(:name)
              end
              all_data << rec
            when 'region'
              rec['region_id'] = service.region_id
              rec['region_name'] = service.try(:region).try(:region_name) || Region.find_by(id: service.region_id).try(:region_name)
              all_data << rec
            when 'service_type'
              type = TaskService::Fetcher::CommonMethod.set_service_type(service_type, service)
              all_data << type
            when 'resource_group'
              rec['resource_group_id'] = service.azure_resource_group_id
              rec['resource_group'] = service.resource_group_name
              all_data << rec
            when 'service_tags'
              rec['tags'] = if task.provider.eql?('AWS')
                              tags = service.class.name.eql?("MachineImage") ? service.service_tags : service.data.try(:[], "tags")
                              SecurityScanner.convert_tags(tags)
                            elsif task.provider.eql?('Azure')
                              SecurityScanner.convert_tags(service.provider_data.try(:[], 'tags'))
                            elsif task.provider.eql?('VmWare')
                              vm_tags = TaskService::Fetcher::CommonMethod.inventory_tags(service)
                              SecurityScanner.convert_tags(vm_tags)
                            end
              rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(service_type, service)
              all_data << rec
            end
          elsif task.provider.eql?('VmWare')
            rec = vm_ware_data(service, task, rec, service_type)
            all_data << rec
          else # This when get_opt_out_data is invoked
            rec['provider_id'] = service.class.name.eql?("MachineImage") ? service.image_id : service.provider_id
            rec['cost_by_hour'] = service.cost_by_hour.to_f
            rec['region'] = service.try(:region).try(:region_name) || Region.find_by(id: service.region_id).try(:region_name)
            rec['region_id'] = service.region_id
            rec['task_id'] = task.id
            rec['adapter_id'] = service.try(:adapter).try(:id)
            rec['task_title'] = task.title
            rec['name'] = service.name.nil? ? service.provider_id : service.name
            rec['platform'] = service.try(:platform)
            rec['owner'] = task.creator.name
            rec['adapter_name'] = service.class.name.eql?('MachineImage') ? service.adapter_name : service.try(:adapter).try(:name)
            rec['account_id'] = task.account_id
            rec['email'] = task.creator.email
            rec['start_date_time'] = ''
            rec['ordered'] = false
            rec['notify_to_email'] = task.notify_to_email.present? ? task.notify_to_email : nil
            rec['notify_to_tag_name'] = TaskService::Fetcher::CommonMethod.store_notify_to_tag_name(task, service)
            rec['dry_run'] = task.is_dry_run == true
            rec['provider'] = task.provider
            if task.provider.eql?('AWS')
              rec['state'] = TaskService::Fetcher::CommonMethod.set_service_state(service)
              rec['monthly_estimated_cost'] = service.get_monthly_estimated_cost.to_f
              rec['tags'] = TaskService::Fetcher::CommonMethod.service_tags(task, service)
              rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(service_type, service)
            else
              rec['state'] = TaskService::Fetcher::CommonMethod.set_service_state_for_azure(service)
              rec['monthly_estimated_cost'] = service.cost_by_hour.present? ? (service.cost_by_hour * 24 * 30).to_f : nil
              rec['tags'] = TaskService::Fetcher::CommonMethod.service_tags(task, service)
              rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(service_type, service)
              rec['resource_group'] = service.resource_group_name
              rec['resource_group_id'] = service.azure_resource_group_id
            end
            all_data << rec
          end
        end
      end
      all_data.uniq
    end

    def get_task_services_with_filters(account, task, task_params)
      all_data = task.account_id == account.id ? get_task_services(task) : [] # get all task services with appropiate data

      # filter data accordingly search
      task_params['service_type'].present? && all_data.select! { |data| data['service_type'] == task_params['service_type'] }
      task_params['adapter_id'].present? && all_data.select! { |data| data['adapter_id'] == task_params['adapter_id'] }
      task_params['region'].present? && all_data.select! { |data| data['region'] == task_params['region'] }
      if task_params['azure_resource_group_id'].present? && task.type.eql?('Task::Azure')
        all_data.select! { |data| data['resource_group_id'] == task_params['azure_resource_group_id'] }
      end

      tags = JSON.parse(task_params['tags'] || '[]')
      if tags.present?
        tag_key = tags['tag_key']
        tag_value = tags['tag_value']
        tag_sign = tags['tag_sign']
        if tag_value.present? && tag_key.present?
          if tag_sign.eql?('=')
            all_data.select! { |data| data['tags'].present? && data['tags'].include?({ 'tag_key' => tag_key, 'tag_value' => tag_value }) }
          else
            all_data.reject! { |data| data['tags'].present? && data['tags'].include?({ 'tag_key' => tag_key, 'tag_value' => tag_value }) }
          end
        end
      end

      total_savings = 0
      unless task.provider.eql?('VmWare')
        total_savings = total_monthly_estimated_savings(all_data)

        if task_params['sort_by'].present? && task_params['sort_by'] == 'asc'
          all_data.sort_by! { |data| data['monthly_estimated_cost'] }
        else
          all_data.sort_by! { |data| data['monthly_estimated_cost'] }.reverse!
        end
      end

      fetch_opt_out_services, total_records = data_pagination(all_data, task_params)
      [fetch_opt_out_services, total_records, total_savings, custom_email_data(task, true)]
    end

    def provider_service_types(task)
      if task.provider.eql?('AWS')
        %w[services snapshots machine_image]
      elsif task.provider.eql?('Azure')
        %w[resources]
      elsif task.provider.eql?('VmWare')
        %w[inventories]
      end
    end

    def vm_ware_data(service, task, rec, service_type)
      rec['provider_id'] = service.provider_id
      rec['task_id'] = task.id
      rec['adapter_id'] = service.vw_vcenter.adapter_id
      rec['task_title'] = task.title
      rec['name'] = service.tag
      rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(service_type, service)
      rec['owner'] = task.creator.name
      rec['adapter_name'] = service.inventory_adapter.name
      rec['account_id'] = task.account_id
      rec['email'] = task.creator.email
      rec['start_date_time'] = ''
      rec['tags'] = SecurityScanner.convert_tags(TaskService::Fetcher::CommonMethod.inventory_tags(service))
      rec['notify_to_email'] = task.notify_to_email.present? ? task.notify_to_email : nil
      rec['notify_to_tag_name'] = TaskService::Fetcher::CommonMethod.vmware_notify_to_tag_name(task, TaskService::Fetcher::CommonMethod.inventory_tags(service))
      rec['dry_run'] = task.is_dry_run == true
      rec['provider'] = task.provider
      rec['vw_vcenter_id'] = service.vw_vcenter_id
      rec['state'] = service.inventory_state
      rec
    end

    def custom_email_data(task, dry_run=false)
      data = {}
      # Considering that custom email template will be present for all three mails - opt out, dry_run_opt_out, dry_run_event_notification
      is_custom_email = task.account.organisation.email_templates.event_scheduler_template.present?
      data.merge!(is_custom_email: is_custom_email)
      return data unless is_custom_email

      date = CustomerioNotifier.get_date_in_time_zone(task.creator)
      email_template = if dry_run
                         task.account.organisation.email_templates.event_scheduler_template.find_by(template_type: EmailTemplates::EventScheduler.template_types["dry_run_event_notification"])
                        elsif task.is_dry_run
                          task.account.organisation.email_templates.event_scheduler_template.find_by(template_type: EmailTemplates::EventScheduler.template_types["dry_run_opt_out"])
                        else
                          task.account.organisation.email_templates.event_scheduler_template.find_by(template_type: EmailTemplates::EventScheduler.template_types["opt_out"])
                        end

      data.merge!(subject: task.provider + email_template.subject + "#{date}")
      data.merge!(recommendations: EmailTemplates::AdditionalConditions.set_additional_conditions(task.additional_conditions_value)) if task.additional_conditions.present? && task.additional_conditions_value.present?
      data
    end
  end
end
