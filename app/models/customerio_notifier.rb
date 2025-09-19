class CustomerioNotifier

  def self.beta_signed_up(user_id)
    user = User.find(user_id)

    create_unconfirmed_user(user)

    $customerio.track(
      user.id,
      :beta_signed_up
    )
  end

  def self.confirm_user(user_id, host=Settings.host)
    user = User.find(user_id)

    create_unconfirmed_user(user)

    send_confirmation_email(user_id, host)
  end

  def self.account_deactivation(organisation_id)
    organisation = Organisation.find(organisation_id)
    user = organisation.owner

    $customerio.identify(
      id: user.id,
      email: user.email,
      organisation_name: (organisation.name || organisation.account.name || organisation.subdomain).capitalize
    )
    $customerio.track(
      user.id,
      :account_deactive,
      username: get_user_name(user),
      email: user.email,
      organisation_name: (organisation.name || organisation.account.name || organisation.subdomain).capitalize
    )
  end

  def self.account_reactivation(organisation_id)
    organisation = Organisation.find(organisation_id)
    user = organisation.owner

    $customerio.identify(
      id: user.id,
      email: user.email,
      organisation_name: (organisation.name || organisation.account.name || organisation.subdomain).capitalize
    )
    $customerio.track(
      user.id,
      :account_reactive,
      username: user.username.capitalize,
      email: user.email,
      organisation_name: (organisation.name || organisation.account.name || organisation.subdomain).capitalize
    )
  end

  def self.send_confirmation_email(user_id, host)
    user = User.find(user_id)
    base64_encoded_token = fetch_signup_token(user)

    $customerio.track(
      user.id,
      :confirm_user,
      host: host,
      username: get_user_name(user),
      confirmation_token: base64_encoded_token
    )
  end

  def self.fetch_signup_token(user)
    hosted_zone_name =  ENV["HOSTED_REGION"].present? ? CommonConstants::HOSTED_REGIONS[ENV["HOSTED_REGION"]] : CommonConstants::DEFAULT_REGIONS[Rails.env]
    hosted_zone_code = CommonConstants::AZ_CODES.key(hosted_zone_name).to_s
    token_with_region = { confirmation_token: user.confirmation_token, hosted_zone: hosted_zone_code }
    Base64.strict_encode64(JSON.dump(token_with_region))
  end

  def self.invite_user(user_id)
    user = User.find(user_id)

    $customerio.identify(
      id: user.id,
      invite_token: user.invite_token
    )

    $customerio.track(
      user.id,
      :beta_invited,
      host: Settings.host,
      invite_token: user.invite_token
    )
  end

  def self.invite_group_user(user_id, invite_token, host)
    user = User.find(user_id)

    create_unconfirmed_user(user)

    $customerio.track(
      user.id,
      :user_invite,
      host: host,
      username: 'Customer',
      invite_token: invite_token
    )
  end

  def self.disable_mfa(user_id, user_mfa_token, host=Settings.host)
    user = User.find(user_id)
    $customerio.identify(
      id: user.id,
      user_mfa_token: user_mfa_token
    )
    $customerio.track(
      user.id,
      :disable_mfa,
      host: host,
      user_mfa_token: user_mfa_token,
      username: get_user_name(user),
    )
  end

  # this is a opt-out email for services
  def self.event_notification_report_email(email, task_id, event_start_date_time, template_data, url, options, email_is_a_array=false)
    with_rescue do
      ESLog.info "----IN CUSTOMER IO---event_notification_report_email-----------------------"
      task = Task.find(task_id)
      user = task.creator
      user_id = SecureRandom.uuid
      email = email_is_a_array ? email.join(', ') : email
      ESLog.info "===MAIL SEND TO===#{email}==============="
      $customerio.identify(
        id: user.nil? ? user_id : user.id,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task_id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        notify_tag: options[:notify_to_tag_name],
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
      $customerio.track(
        user.nil? ? user_id : user.id,
        :ec2_right_sizing_instances_report_email,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task_id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        notify_tag: options[:notify_to_tag_name],
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
    end
  end

  def self.custom_event_notification_report_email(email, task, email_template, email_is_a_array=false)
    with_rescue do
      ESLog.info "----IN CUSTOMER IO---custom event_notification_report_email-----------------------"
      user = task.creator
      user_id = SecureRandom.uuid
      email = email_is_a_array ? email.join(', ') : email
      date = get_date_in_time_zone(user)
      ESLog.info "===MAIL SEND TO===#{email}==============="
      $customerio.identify(
        id: user.nil? ? user_id : user.id,
        email: email,
        subject: email_template.task_provider + email_template.subject + "#{date}",
        body: email_template.build_body,
        link: email_template.build_link
      )
      $customerio.track(
        user.nil? ? user_id : user.id,
        :custom_dry_run_test_mail,
        email: email,
        subject: email_template.task_provider + email_template.subject + "#{date}",
        body: email_template.build_body,
        link: email_template.build_link
      )
    end
  end

  # this is same as opt-out email but template is different in customer io
  def self.opt_out_email_for_dry_run_event(email, task_id, event_start_date_time, template_data, url, options, email_is_a_array=false)
    with_rescue do
      ESLog.info "----IN CUSTOMER IO---opt_out_email_for_dry_run_event-----------------------"
      task = Task.find(task_id)
      user = task.creator
      user_id = SecureRandom.uuid
      email = email_is_a_array ? email.join(', ') : email
      ESLog.info "===MAIL SEND TO===#{email}==============="
      $customerio.identify(
        id: user.nil? ? user_id : user.id,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task_id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        notify_tag: options[:notify_to_tag_name],
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
      $customerio.track(
        user.nil? ? user_id : user.id,
        :opt_out_email_for_dry_run_event,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task_id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        notify_tag: options[:notify_to_tag_name],
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
    end
  end

  # This mail send information of event's details run in testing mode
  def self.dry_run_email_notification_to_user(email, task_id, event_start_date_time, template_data, url, options, email_is_a_array=false)
    with_rescue do
      ESLog.info "----IN CUSTOMER IO---dry_run_email_notification_to_user-----------------------"
      user = User.find_by(email: email)
      user_id = SecureRandom.uuid
      task = Task.find(task_id)
      ESLog.info "===MAIL SEND TO===#{email}==============="
      $customerio.identify(
        id: user.nil? ? user_id : user.id,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task.id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
      $customerio.track(
        user.nil? ? user_id : user.id,
        :dry_run_email_notification_to_user,
        email: email,
        username: set_user_name_value(user, email),
        task_title: task.title,
        event_start_date_time: event_start_date_time.to_datetime.strftime("%a, %d %b %Y at %I:%M %P"),
        instance_names: template_data,
        host: url,
        task_id: task_id,
        task_type: set_task_type(task.task_type),
        additional_data: additional_data(task.task_type),
        link_email: email_is_a_array ? "all" : email,
        provider: task.provider.eql?('VmWare') ? 'VMware' : task.provider,
        additional_condition: task_additional_condition(task.additional_conditions),
        additional_condition_values: options[:additional_template_data],
        total_services: options[:total_services],
        monthly_estimated_savings: options[:monthly_estimated_savings],
        listed_services: options[:listed_services]
      )
    end
  end

  def self.custom_dry_run_email_notification_to(email, task, email_template)
    with_rescue do
      ESLog.info "----IN CUSTOMER IO---custom-dry_run_email_notification_to_user-----------------------"
      user = User.find_by(email: email)
      user_id = SecureRandom.uuid
      date = get_date_in_time_zone(user)

      ESLog.info "===MAIL SEND TO===#{email}==============="
      $customerio.identify(
        id: user.nil? ? user_id : user.id,
        email: email,
        subject: email_template.task_provider + email_template.subject + "#{date}",
        body: email_template.build_body,
        link: email_template.build_link
      )
      $customerio.track(
        user.nil? ? user_id : user.id,
        :custom_dry_run_test_mail,
        email: email,
        subject: email_template.task_provider + email_template.subject + "#{date}",
        body: email_template.build_body,
        link: email_template.build_link
      )
    end
  end

  def self.set_user_name_value(user, email)
    if user.nil?
      email.split('@').first.capitalize
    else
      get_user_name(user)
    end
  end

  def self.set_task_type(task_type)
    if task_type.eql?('env_terminate')
      "Termination"
    elsif task_type.eql?('env_ec2_right_size')
      "RightSizing"
    elsif task_type.eql?('env_stop')
      "Stop"
    elsif task_type.eql?('env_start')
      "Start"
    elsif task_type.eql?('env_start_stop')
      "Start-Stop"
    elsif task_type.eql?('backup_services')
      "Backup"
    end
  end

  def self.additional_data(task_type)
    if task_type.eql?('env_ec2_right_size')
      "their recommended sizes or to"
    else
      "to"
    end
  end

  def self.granted_admin_role(user_id, account_id)
    user    = User.find(user_id)
    account = Account.find(account_id)

    $customerio.track(
      user.id,
      :granted_admin,
      host: Settings.host,
      account_name: account.name
    )
  end

  def self.user_signed_up(user_id, host=Settings.host)
    user = User.find(user_id)

    $customerio.track(
      user.id,
      :signed_up,
      host: host
    )

    $customerio.identify(
      id: user.id,
      created_at: user.created_at.to_i,
      email: user.email,
      name: user.name,
      username: user.username
    )
  end

  # TODO: this is used from the bin file - check in the future if we still need it. I believe we do for now.
  def self.assign_invite(user_id)
    user = User.find(user_id)

    $customerio.identify(
      id: user.id,
      email: user.email
    )

    $customerio.track(
      user.id,
      :beta_signed_up,
      host: Settings.host,
      invite_token: user.invite_token
    )
  end

  def self.create_unconfirmed_user(user)
    $customerio.identify(
      id: user.id,
      created_at: user.created_at.to_i,
      email: user.email || user.unconfirmed_email
    )
  end

  def self.reset_password_requested(user, token, host=Settings.host)
    $customerio.identify(
      id: user.id,
      email: user.email
    )

    $customerio.track(
      user.id,
      :reset_password_requested,
      username: get_user_name(user),
      host: host,
      token: token
    )
  end

  def self.request_demo(options={})
    get_val = ->(val) { val.blank? ? '-' : val }
    $customerio.track(1, :requestdemo,
                      name: get_val.call(options[:name]),
                      organisation: get_val.call(options[:organisation]),
                      title: get_val.call(options[:title]),
                      phone: get_val.call(options[:phone]),
                      email: get_val.call(options[:email]),
                      preferred_time: get_val.call(options[:preferred_time]))
  end

  def self.send_credentials_updated_email(user)
    $customerio.identify(
      id: user.id,
      email: user.email
    )
    $customerio.track(
      user.id,
      :send_credentials_updated_email,
      host: Settings.host,
      username: get_user_name(user),
      email: user.email
    )
  end

  def self.send_invoice_generated_email(user, period)
    $customerio.identify(
      id: user.id,
      email: user.email,
      username: get_user_name(user)
    )

    $customerio.track(
      user.id,
      :invoice_generated,
      month: period.to_s,
      host: Settings.host,
      username: get_user_name(user),
      email: user.email
    )
  end

  def self.send_application_limit_crossed_email(user, application_name)
    $customerio.identify(
      id: user.id,
      email: user.email,
      username: get_user_name(user)
    )

    $customerio.track(
      user.id,
      :application_cost_alert,
      application_name: application_name,
      host: Settings.host,
      username: get_user_name(user),
      email: user.email
    )
    # TODO: use anonymous track to send emails at once after customerio is updated.
    # $customerio.anonymous_track(
    #   :application_cost_alert,
    #   :application_name => application_name,
    #   :recipient => emails.join(','))
  end

  def self.send_account_budget_limit_crossed_email(user, info, budget_data_template)
    with_rescue do
      BudgetProcess.info "----IN CUSTOMER IO---over budget email_notification_to #{user.try(:email)}, Budget Details: #{info}---, Template Details: #{budget_data_template}--------"
      $customerio.identify(
        id: user.id,
        email: user.email,
        username: get_user_name(user)
      )
      $customerio.track(
        user.id,
        :account_budget_cost_alert,
        account_budget_name: info[:budget_name],
        accounts: info[:accounts],
        subject_type: info[:subject_type],
        host: Settings.host,
        username: get_user_name(user),
        email: user.email,
        currency: info[:currency],
        cost_to_date: info[:cost_to_date],
        max_amount: info[:max_amount],
        budget_data_template: budget_data_template
      )
    end
  end

  def self.send_account_budget_threshold_limit_email(user, info, budget_data_template)
    with_rescue do
      BudgetProcess.info "----IN CUSTOMER IO---threshold budget email_notification_to #{user.try(:email)}, Budget Details: #{info}------,Template Details: #{budget_data_template}"
      $customerio.identify(
        id: user.id,
        email: user.email,
        username: get_user_name(user)
      )
      $customerio.track(
        user.id,
        :account_budget_threshold_limit_alert,
        account_budget_name: info[:budget_name],
        accounts: info[:accounts],
        host: Settings.host,
        username: get_user_name(user),
        email: user.email,
        currency: info[:currency],
        cost_to_date: info[:cost_to_date],
        max_amount: info[:max_amount],
        threshold_limit: info[:threshold_limit],
        threshold_value: info[:threshold_value],
        budget_data_template: budget_data_template
      )
    end
  end

  def self.send_account_budget_limit_crossed_to_custom_email(admin, info, email, budget_data_template)
    with_rescue do
      BudgetProcess.info "----IN CUSTOMER IO---over budget email_notification_to custom email #{email}, Budget Details: #{info} Template Details: #{budget_data_template}-----------"
      user = User.find_by_email(email)
      user_name = user.present? ? get_user_name(user) : 'Customer'
      $customerio.identify(
        id: admin,
        email: email,
        username: user_name
      )
      $customerio.track(
        admin,
        :account_budget_cost_alert,
        account_budget_name: info[:budget_name],
        accounts: info[:accounts],
        subject_type: info[:subject_type],
        host: Settings.host,
        username: user_name,
        email: email,
        currency: info[:currency],
        cost_to_date: info[:cost_to_date],
        max_amount: info[:max_amount],
        budget_data_template: budget_data_template
      )
    end
  end

  def self.send_account_budget_threshold_limit_to_custom_email(admin, info, email, budget_data_template)
    with_rescue do
      BudgetProcess.info "----IN CUSTOMER IO---threshold budget email_notification_to custom email #{email},  Budget Details: #{info}----, Template Details: #{budget_data_template}"
      user = User.find_by_email(email)
      user_name = user.present? ? get_user_name(user) : 'Customer'
      $customerio.identify(
        id: admin,
        email: email,
        username: user_name
      )
      $customerio.track(
        admin,
        :account_budget_threshold_limit_alert,
        account_budget_name: info[:budget_name],
        accounts: info[:accounts],
        host: Settings.host,
        username: user_name,
        email: email,
        currency: info[:currency],
        cost_to_date: info[:cost_to_date],
        max_amount: info[:max_amount],
        threshold_limit: info[:threshold_limit],
        threshold_value: info[:threshold_value],
        budget_data_template: budget_data_template
      )
    end
  end

  def self.favorite_report_email(fav_report_name, fav_id, email, mail_frequency, subdomain, fav_scheduled_name, account_id)
    organisation = Organisation.find_by_subdomain(subdomain)
    host = organisation.host_url
    user = User.find_by_email(email)
    username = (user.present? ? get_user_name(user) : 'Customer')

    $customerio.identify(
      id: fav_id,
      email: email,
      username: username,
      account: account_id,
      favourite_report_id: fav_id,
      fav_report_name: fav_report_name,
      host: host,
      mail_frequency: mail_frequency,
      fav_scheduled_name: fav_scheduled_name
    )

    $customerio.track(
      fav_id,
      :favourite_report_email,
      favourite_report_id: fav_id,
      account: account_id,
      host: host,
      username: username,
      email: email,
      fav_report_name: fav_report_name,
      mail_frequency: mail_frequency,
      fav_scheduled_name: fav_scheduled_name
    )
  end

  def self.send_user_followup(user_id, account_id, type)
    return unless FollowUpEmailHistory::EMAIL_TYPE_MAP.values.flatten.include?(type)

    user = User.find(user_id)
    $customerio.identify(
      id: user.id,
      email: user.email,
      username: user.username,
      name: get_user_name(user),
      host: Settings.host,
      account_id: account_id
    )

    $customerio.track(
      user.id,
      type,
      host: Settings.host,
      account_id: account_id,
      username: user.username,
      name: get_user_name(user),
      email: user.email
    )
  end

  def self.event_logs_email(task, logs_data_template, user, url, log_type, custom_flag)
    mail_content = format_event_logs(task, log_type)
    mail_id = custom_flag ? task.id : user.id
    username = custom_flag ? 'Customer' : get_user_name(user)
    email = custom_flag ? user.join(', ') : user.email
    $customerio.identify(
      id: mail_id,
      email: email,
      bcc_mails: '',
      username: username,
      logs_data_template: logs_data_template,
      host: url,
      task_title: task.title,
      subject: mail_content['subject'],
      details: mail_content['details'],
      provider: task.provider
    )
    $customerio.track(
      mail_id,
      :event_logs_email,
      email: email,
      bcc_mails: '',
      username: username,
      logs_data_template: logs_data_template,
      host: url,
      task_title: task.title,
      subject: mail_content['subject'],
      details: mail_content['details'],
      provider: task.provider
    )
  end

  # Add different email for dry run event notification.
  def self.dry_run_event_logs_email(task, logs_data_template, user, url, log_type, custom_flag)
    mail_content = format_event_logs(task, log_type)
    mail_id = custom_flag ? task.id : user.id
    username = custom_flag ? 'Customer' : get_user_name(user)
    email = custom_flag ? user.join(', ') : user.email
    $customerio.identify(
      id: mail_id,
      email: email,
      bcc_mails: '',
      username: username,
      logs_data_template: logs_data_template,
      host: url,
      task_title: task.title,
      subject: mail_content['subject'],
      details: mail_content['details'],
      provider: task.provider
    )
    $customerio.track(
      mail_id,
      :dry_run_event_logs_email,
      email: email,
      bcc_mails: '',
      username: username,
      logs_data_template: logs_data_template,
      host: url,
      task_title: task.title,
      subject: mail_content['subject'],
      details: mail_content['details'],
      provider: task.provider
    )
  end

  def self.event_failure_email(task, details, url, mails)
    with_rescue do
      ESLog.info "============Sending Failure mail for task=#{task.title}=with id:#{task.id}===="
      $customerio.identify(
        id: task.id,
        email: mails,
        bcc_mails: '',
        username: "admin",
        logs_data_template: '',
        host: url,
        task_title: task.title,
        subject: "[CloudStreet] Task Run Failure for #{task.title}",
        details: details,
        provider: task.provider
      )
      $customerio.track(
        task.id,
        :event_logs_email,
        email: mails,
        bcc_mails: '',
        username: "admin",
        logs_data_template: '',
        host: url,
        task_title: task.title,
        subject: "[CloudStreet] Task Run Failure for #{task.title}",
        details: details,
        provider: task.provider
      )
    end
  end

  def self.format_event_logs(task, log_type)
    subject = ''
    details = ''
    user = task.creator
    time_zone = user.time_zone.map { |_k, v| [v].flatten.join(',').to_s }.uniq.join('/')
    if task.task_type.eql?("env_start_stop")
      email_log_time = task.data["start_stop_last_execuation_time"].present? ? task.data["start_stop_last_execuation_time"] : last_execuation_time
      last_execuation_time = email_log_time.in_time_zone(TZInfo::Timezone.get(time_zone)).strftime("%a, %B %d, %Y %I:%M:%S %P %Z")
    else
      last_execuation_time = task.last_execuation_time.in_time_zone(TZInfo::Timezone.get(time_zone)).strftime("%a, %B %d, %Y %I:%M:%S %P %Z")
    end

    # Accordingly the log type the mail content is set
    case log_type
    when 'all_logs'
      subject = "[CloudStreet] Event Success with Errors '#{task.title}'"
      progress = task.progress
      notification_status =  if progress['total'] == progress ['success']
        'Success'
      elsif progress['total'] == progress ['failure']
        'Errors'
      else
        'Success with Errors'
      end
      details = "<br><strong>EVENT NOTIFICATION</strong><br/><br/>Category: Event<br/>Event Name: '#{task.title}'<br/>Notification Status: #{notification_status}<br/> Executed: #{last_execuation_time}.<br/>Event Accounts: #{task.adapters&.pluck(:name)&.join(', ')}<br/><br/>NOTE: Complete Event Logs"
    when 'failed_logs'
      subject = "[CloudStreet] Event Error '#{task.title}'"
      details = "<br><strong>EVENT FAILURE NOTIFICATION</strong><br/><br/>Category: Event<br/>Event Name: '#{task.title}'<br/>Notification Status: Error<br/> Executed: #{last_execuation_time}.<br/>Event Accounts: #{task.adapters&.pluck(:name)&.join(', ')}<br/><br/> NOTE: Complete Event Logs"
    when 'success_logs'
      subject = "[CloudStreet] Event Success '#{task.title}'"
      details = "<br><strong>EVENT SUCCESS NOTIFICATION</strong><br/><br/>Category: Event<br/>Event Name: '#{task.title}'<br/>Notification Status: Success<br/> Executed: #{last_execuation_time}.<br/>Event Accounts: #{task.adapters&.pluck(:name)&.join(', ')}<br/><br/> NOTE: Complete Event Logs"
    end
    {'subject' => subject, 'details' => details}
  end

  def self.get_user_name(user)
    user.attributes["name"].blank? ? user.username : user.attributes["name"].titleize
  end

  def self.threat_notification_mail(notification_config, threat_rules, threat_data_template, user, url, custom_flag)
    mail_id = custom_flag ? notification_config.id : user.id
    username = custom_flag ? 'Customer' : get_user_name(user)
    email = custom_flag ? user.join(', ') : user.email
    $customerio.identify(
      id: mail_id,
      email: email,
      username: username,
      host: url,
      subject: 'Security Adviser Security Rule change'
    )
    $customerio.track(
      mail_id,
      :security_threat_email_notification,
      email: email,
      username: username,
      threat_data_template: threat_data_template,
      threat_rules: threat_rules.join(","),
      severity: notification_config.severity.map(&:titlecase).join(","),
      host: url,
      subject: 'Security Adviser Security Rule change',
      notification_name: notification_config.name
    )
  end

  def self.task_additional_condition(additional_conditions)
    return unless additional_conditions.present?

    if additional_conditions.eql?("idle")
      "IDLE Running and Stopped"
    elsif additional_conditions.eql?("idle_running")
      "IDLE Running"
    elsif additional_conditions.eql?("idle_stopped")
      "IDLE Stopped"
    end
  end

  def self.export_report(excel, email)
    user = User.find_by_email(email)
    return if user.blank?

    $customerio.identify(
      id: User.find_by_email(email).id,
      email: email,
      excel: excel,
      username: get_user_name(user),
      account: User.find_by_email(email).account_id,
    )

    $customerio.track(
      User.find_by_email(email).id,
      :export_report,
      excel: excel,
      account: User.find_by_email(email).account_id,
      username: get_user_name(user),
      email: email
    )
  end

  def self.get_date_in_time_zone(user)
    if user.present?
      time_zone = user.time_zone.values.uniq.join('/')
      Date.today.in_time_zone(TZInfo::Timezone.get(time_zone)).strftime("%a, %d %b %Y")
    else
      Date.today.strftime("%a, %d %b %Y")
    end
  end

  def self.with_rescue
    yield
  rescue Customerio::Client::InvalidResponse => e
    ESLog.info "============#{e.message}========#{e.class}======"
    Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
  end

  def self.sa_recommendation_created(user_id, service_details, email, username, host=Settings.host)
    user = User.find(user_id)
    provider =  service_details.first.type.split("::").last.downcase rescue ''
    category =  service_details.first.category rescue ''
    $customerio.identify(
      id: user.id,
      email: email,
      subject: '[Action Required][CloudStreet CSMP Cost Service Adviser Recommendation]'
    )
    $customerio.track(
      user.id,
      :sa_recommendation,
      host: host,
      subject: '[Action Required][CloudStreet CSMP Cost Service Adviser Recommendation]',
      template_data: set_sa_recommendation_template(service_details, host, provider, category),
      email: email,
      username: username,
    )
  end

  def self.sa_recommendation_completed(recommendation_id, host=Settings.host)
    sa_recommendation  = SaRecommendation.find recommendation_id
    category = sa_recommendation.category 
    user = User.find(sa_recommendation.user_id)
    provider =  sa_recommendation.type.split("::").last.downcase rescue ''

    $customerio.identify(
      id: user.id,
      subject: '[CloudStreet CSMP Cost Service Adviser Recommendation]'
    )
    $customerio.track(
      user.id,
      :sa_recommendation_completed,
      host: host,
      subject: '[CloudStreet CSMP Cost Service Adviser Recommendation]',
      template_data: set_sa_recommendation_template([sa_recommendation], host, provider, category),
      username: user.username,
      task_name: sa_recommendation.recommendation_service&.name
    )
  end

  def self.set_sa_recommendation_template(data, host, provider, category)
    template = ERB.new <<-EOF
      <div>
        <table style="width: 100%;text-align: center;border-collapse: collapse;">
          <thead style="font-weight: 500;font-size: 14px;background-color: #f9f9f9;">
          <tr>
          <td style="border: 1px solid #c7c4c4;">Cloud provider name</td>
          <td style="border: 1px solid #c7c4c4;">Category</td>
          <td style="border: 1px solid #c7c4c4;">Service type</td>
          <td style="border: 1px solid #c7c4c4;"><% if provider == 'azure' %> Resource Name <% else %> Service Name <% end %></td>
          <td style="border: 1px solid #c7c4c4;">Assigner Comment</td>
          <td style="border: 1px solid #c7c4c4;"><% if category == 'unused' %> MEC <% else %> Total saving <% end %></td>
          </tr>
          </thead>
          <tbody>
            <% data.each_with_index do |d, index| %>
              <% service = d.recommendation_service %>
              <tr>
                <td style="border: 1px solid #c7c4c4;"><%= d['type'].split('::').last %></td>
                <td style="border: 1px solid #c7c4c4;"><%= d['category'].capitalize %></td>
                <td style="border: 1px solid #c7c4c4;"><%= ServiceAdviser::Helpers::Common::SERVICE_TYPE[d['service_type']] || d['service_type'] %></td>
                <td style="border: 1px solid #c7c4c4;">
                  <% if d['state'].eql?('completed') %>
                    <%= service&.name %>
                  <% else %>
                    <a href="#{host}/service-adviser/#{provider}/all?tab=task" target="_blank">
                      <%= service&.name %>
                    </a>
                  <% end %>
                </td>
                <td style="border: 1px solid #c7c4c4;"><%= d['assigner_comment'] %></td>
                <td style="border: 1px solid #c7c4c4;"><%= d.recommendation_mec %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
      </div>
    EOF
    template.result(binding)
  end

  def self.send_policy_task_recommendation_email(email, csv_data)
    subject = '[Action Required][CloudStreet CSMP Cost Service Adviser Recommendation]'

    request = Customerio::SendEmailRequest.new(
      to: email,
      from: 'support@cloudstreet.com',
      transactional_message_id: ENV['TRANSACTION_MESSAGE_ID'],
      subject: subject,
      message_data: {
        username: email
      },
      identifiers: { email: email }
    )
    # request.attach("recommendation_task_list.xls", csv_data)
    begin
      response = $customerioApiClient.send_email(request)
      CSLogger.info response
    rescue Customerio::InvalidResponse => e
      CSLogger.error e.code, e.message
    end
  end


end
