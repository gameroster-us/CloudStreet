# Azure Opt-Out Notification
class AzureOptOutEventNotificationWorker
  include Sidekiq::Worker

  sidekiq_options queue: :task_queue, retry: false, backtrace: true

  def perform(*args)
    ESLog.info "======#{args}========="
    user = User.find_by(id: args[0]['user_id'])
    task = Task::Azure.find_by(id: args[0]['task_id'])
    return unless task.present?
    return if task.task_type.eql?('env_start_stop')

    event_start_date_time = args[0]['event_start_date_time']
    check_new_service = args[0]['check_new_service']
    ESLog.info "===before====#{task.title}======#{task.resources.count}======"
    if check_new_service.present? && check_new_service
      task.reset_task_environments(false) # Passed false beacuse dont want to send notification
      task.services_prepared
    end
    ESLog.info "===after====#{task.title}======#{task.resources.count}======"
    send_mail(task, user, event_start_date_time)
  rescue => e
    ESLog.error e.message
    ESLog.error e.backtrace
  end

  def send_mail(task, user, event_start_date_time)
    ESLog.info "=======send_mail========#{task.title}=================="
    return unless task.resources.present?

    save_data_to_event_notification(task, user, task.resources.pluck(:id), event_start_date_time, 'resources')
    send_email_notification_to_user(task, user, event_start_date_time)
  end

  def save_data_to_event_notification(task, user, service_provider_ids, event_start_date_time, type)
    start_date_time = event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %H:%M %P")
    adapter_ids = task.adapter_group_ids.present? ? ServiceGroup.adapterids_from_adapter_group(adapter_group_ids) : task.adapter_ids
    resources = Azure::Resource.where(id: service_provider_ids, adapter_id: adapter_ids) if type.eql?('resources')
    store_data_to_event_table(task, user, resources, start_date_time, type)
  rescue => e
    ESLog.error e.message
  end

  def store_data_to_event_table(task, user, resources, start_date_time, type)
    ESLog.info "-------store_data_to_event_table-------#{task.title}--------------"
    ri_data = []
    provider_ids = []
    instance_ids = []
    ESLog.info "===#{resources.count}========="
    resources.each do |resource|
      rec = {}
      rec['provider_id'] = resource.provider_id
      rec['cost_by_hour'] = resource.cost_by_hour.to_f
      provider_ids << rec['provider_id']
      event_data = EventNotificationData.where(task_id: task.id, provider_id: rec['provider_id'])
      if event_data.exists?
        update_event_data(event_data, resource, task, rec, type, user, start_date_time) if event_data.exists?
        next
      end
      rec['region'] = resource.try(:region).try(:region_name) || Region.find_by(id: resource.region_id).try(:region_name)
      rec['region_id'] = resource.region_id
      rec['task_id'] = task.id
      rec['adapter_id'] = resource.try(:adapter).try(:id)
      rec['task_title'] = task.title
      rec['name'] = resource.name.nil? ? resource.provider_id : resource.name
      rec['platform'] = resource.try(:platform)
      rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(type, resource)
      rec['owner'] = task.creator.name
      rec['adapter_name'] = resource.try(:adapter).try(:name)
      rec['account_id'] = task.account_id
      rec['email'] = user.email
      rec['start_date_time'] = start_date_time
      rec['ordered'] = false
      rec['tags'] = TaskService::Fetcher::CommonMethod.service_tags(task, resource)
      rec['notify_to_email'] = task.notify_to_email.present? ? task.notify_to_email : nil
      rec['notify_to_tag_name'] = TaskService::Fetcher::CommonMethod.store_notify_to_tag_name(task, resource)
      rec['dry_run'] = task.is_dry_run == true
      rec['provider'] = task.provider
      rec['resource_group'] = resource.resource_group_name
      rec['resource_group_id'] = resource.azure_resource_group_id
      rec['state'] = TaskService::Fetcher::CommonMethod.set_service_state_for_azure(resource)
      rec['monthly_estimated_cost'] = resource.cost_by_hour.present? ? (resource.cost_by_hour * 24 * 30).to_f : nil
      ri_data << rec
    end
    ri_data.each { |h| h.delete('_id') }
    EventNotificationData.collection.insert_many(ri_data) if ri_data.any?
    remove_old_event_data(task, provider_ids, type)
  end

  def update_event_data(event_data, resource, task, rec, type, user, start_date_time)
    rec['region'] = resource.try(:region).try(:region_name) || Region.find_by(id: resource.region_id).try(:region_name)
    rec['region_id'] = resource.region_id
    rec['name'] = resource.name.nil? ? resource.provider_id : resource.name
    rec['platform'] = resource.try(:platform)
    rec['service_type'] = TaskService::Fetcher::CommonMethod.set_service_type(type, resource)
    rec['email'] = user.email
    rec['start_date_time'] = start_date_time
    rec['ordered'] = false
    rec['tags'] = TaskService::Fetcher::CommonMethod.service_tags(task, resource)
    rec['notify_to_email'] = task.notify_to_email.present? ? task.notify_to_email : nil
    rec['notify_to_tag_name'] = TaskService::Fetcher::CommonMethod.store_notify_to_tag_name(task, resource)
    rec['dry_run'] = task.is_dry_run == true
    rec['resource_group'] = resource.try(:resource_group).try(:name)
    rec['resource_group_id'] = resource.azure_resource_group_id
    rec['state'] = TaskService::Fetcher::CommonMethod.set_service_state_for_azure(resource)
    rec['monthly_estimated_cost'] = resource.cost_by_hour.present? ? (resource.cost_by_hour * 24 * 30).to_f : nil
    event_data.update_all(rec)
  end

  def remove_old_event_data(task, provider_ids, type)
    service_types = get_event_service_type(type)
    EventNotificationData.where(task_id: task.id).in(service_type: service_types).not.in(provider_id: provider_ids).delete_all
  end

  def get_event_service_type(type)
    service_types = []
    service_types = ['Virtual Machine', 'Disk', 'Snapshot', 'SQL Database', 'Maria DB', 'PostgreSQL', 'SQL Server', 'MySQL', 'Load Balancer'] if type.eql?('resources')
    service_types
  end

  def send_email_notification_to_user(task, user, event_start_date_time)
    host = task.account.organisation.host_url

    ## for creator + custom email
    custom_mail = task.notify_to_email || []
    email_list = custom_mail.push(user.email).uniq
    ESLog.info "====send_email_notification_to_user====#{email_list}======="
    fetch_data_from_event_notification_data(task, user.email)

    ESLog.info "====Data Present=======#{@template_data.present?}======"
    if @template_data.present?
      send_opt_out_dry_run_mail(email_list, task, event_start_date_time, @template_data, host, true) if task.is_dry_run == true
      send_opt_out_mail(email_list, task, event_start_date_time, @template_data, host, true) unless task.is_dry_run == true
    end

    return unless task.notify_to_tag_name.present?

    task_email = EventNotificationData.where(task_id: task.id, email: user.email).select { |a| a.notify_to_tag_name.present? && a.notify_to_tag_name[task.notify_to_tag_name] }
    email = task_email.pluck(:notify_to_tag_name)
    email = email.map { |a| a[task.notify_to_tag_name] }.uniq
    ESLog.info "===notify_to_tag_name present====#{email}========"
    return unless email.present?

    email.each do |mail|
      next unless TaskService::Fetcher::CommonMethod.is_a_email(mail)

      fetch_data_from_event_notification_data(task, user.email, task.notify_to_tag_name, mail)

      @options[:notify_to_tag_name] = "#{task.notify_to_tag_name} : #{mail}"

      ESLog.info "====Data Present=======#{@template_data.present?}======"

      send_opt_out_dry_run_mail(mail, task, event_start_date_time, @template_data, host) if @template_data.present? && task.is_dry_run == true
      send_opt_out_mail(mail, task, event_start_date_time, @template_data, host) if @template_data.present? && task.is_dry_run != true
    end
  end

  def set_all_data(event_data)
    template = ERB.new <<-EOF
    <div>
    <table style="width: 100%;text-align: center;border-collapse: collapse;">
    <thead style="font-weight: 500;font-size: 14px;background-color: #f9f9f9;">
    <tr>
    <td style="border: 1px solid #c7c4c4;">ID</td>
    <td style="border: 1px solid #c7c4c4;">Resource Name</td>
    <td style="border: 1px solid #c7c4c4;">Resource Type</td>
    <td style="border: 1px solid #c7c4c4;">Adapter</td>
    <td style="border: 1px solid #c7c4c4;">Region</td>
    <td style="border: 1px solid #c7c4c4;">Resource Group</td>
    <td style="border: 1px solid #c7c4c4;">Resource State</td>
    <td style="border: 1px solid #c7c4c4;">$ MES</td>
    </tr>
    </thead>
    <tbody>
    <% event_data.each_with_index do |instance, index| %>
      <tr>
      <td style="border: 1px solid #c7c4c4;"><%= index + 1 %>.</td>
      <td style="border: 1px solid #c7c4c4;"><%= TaskService::Fetcher::CommonMethod.limit_provider_and_name_length(instance[:name]) %></td>
      <td style="border: 1px solid #c7c4c4;"><%= instance[:service_type] %></td>
      <td style="border: 1px solid #c7c4c4;"><%= instance[:adapter_name] %></td>
      <td style="border: 1px solid #c7c4c4;"><%= instance[:region] %></td>
      <td style="border: 1px solid #c7c4c4;"><%= instance[:resource_group] %></td>
      <td style="border: 1px solid #c7c4c4;"><%= instance[:state] %></td>
      <td style="border: 1px solid #c7c4c4;"><%= format("%<number>.2f", number: instance[:monthly_estimated_cost].round(2)) %></td>
      </tr>
    <% end %>
    </tbody>
    </table>
    </div>
    EOF
    template.result(binding)
  end

  def fetch_data_from_event_notification_data(task, email, notify_to_tag=nil, mail=nil)
    5.times do
      sleep(10)
      @data = if notify_to_tag.present? && !notify_to_tag.nil?
                EventNotificationData.where(task_id: task.id, email: email).order_by(monthly_estimated_cost: :desc).select { |a| (a.notify_to_tag_name.present? && a.notify_to_tag_name[notify_to_tag] && a.notify_to_tag_name[notify_to_tag] == mail) }.as_json
              else
                EventNotificationData.where(task_id: task.id, email: email).order_by(monthly_estimated_cost: :desc).as_json
              end
      ESLog.info '......waiting to insert opt-services in database'
      break if @data.present?
    end
    return unless @data.present?

    event_data = @data.each(&:symbolize_keys!)

    @options = {}
    @options[:additional_template_data] = TaskService::OptOut::Template.set_additional_conditions(task.additional_conditions_value) if task.additional_conditions.present? && task.additional_conditions_value.present?
    @options[:monthly_estimated_savings] = TaskService::OptOut::Fetcher.total_monthly_estimated_savings(event_data)
    @options[:total_services] = event_data.count

    loop do
      return unless event_data.present?

      @template_data = set_all_data(event_data)
      ESLog.info "Please wait checking template byte size #{@template_data.bytesize}"
      break if @template_data.bytesize < TaskService::CustomEmail::Helper.opt_out_byte_limit(task)

      event_data.pop
    end
    @options[:listed_services] = event_data.count
  end

  def send_opt_out_mail(email, task, event_start_date_time, template_data, host, email_is_a_array = false)
    org_email_template = task.account.organisation.email_templates.event_scheduler_template.find_by(template_type: EmailTemplates::EventScheduler.template_types["opt_out"])
    if org_email_template
      ESLog.info "=====in custom send_opt_out_mail=========#{email}============"
      TaskService::CustomEmail::Helper.set_body_variables(email, task, org_email_template,event_start_date_time, @options, host, template_data, email_is_a_array)
      CustomerioNotifier.custom_event_notification_report_email(email, task, org_email_template, email_is_a_array)
    else
      ESLog.info "=====in send_opt_out_mail=========#{email}============"
      CustomerioNotifier.event_notification_report_email(email, task.id, event_start_date_time, template_data, host, @options, email_is_a_array)
    end
  end

  def send_opt_out_dry_run_mail(email, task, event_start_date_time, template_data, host, email_is_a_array = false)
    org_email_template = task.account.organisation.email_templates.event_scheduler_template.find_by(template_type: EmailTemplates::EventScheduler.template_types["dry_run_opt_out"])
    if org_email_template
      ESLog.info "=====in custom send_opt_out_dry_run_mail =========#{email}============"
      TaskService::CustomEmail::Helper.set_body_variables(email, task, org_email_template,event_start_date_time, @options, host, template_data, email_is_a_array)
      CustomerioNotifier.custom_event_notification_report_email(email, task, org_email_template, email_is_a_array)
    else
      ESLog.info "=====in send_opt_out_dry_run_mail=====#{email}================"
      CustomerioNotifier.opt_out_email_for_dry_run_event(email, task.id, event_start_date_time, template_data, host, @options, email_is_a_array)
    end
  end

end
