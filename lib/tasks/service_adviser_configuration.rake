# frozen_string_literal: false

namespace :service_adviser_configuration do
  desc 'Create account wise default service adviser confiuration'
  task create: :environment do
    Account.all.each do |account|
      next if ServiceAdviserConfiguration.where(account_id: account.id).exists?

      service_adviser_config = ServiceAdviserConfiguration.new
      service_adviser_config.account_id = account.id
      service_adviser_config.save
      CSLogger.info "======creating default config for account #{account.try(:name)}=========="
    end
  end

  task store_default_configs: :environment do
    desc 'Store account wise default service adviser confiuration'
    Account.all.each do |account|
      begin
        account.create_service_adviser_default_config
        migrate_old_aws_config account
        CSLogger.info "====== Created default config for account #{account.try(:name)}=========="
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
        next
      end
    end
  end

  # Arguments order should be followed while running below rake task
  # 1)rake service_adviser_configuration:add_new_configs  #It will add new metrics to idle condn or remove  old metrics from idle condn for all the services of Azure and AWS providers.
  # 2)rake service_adviser_configuration:add_new_configs[options] # In options we can pass [provider_type, category ,service_type] but order of arguments should be followed.
  # Eg: rake service_adviser_configuration:add_new_configs[azure,idle,virtual_machine] #this will update idle conditions of particular service of particular provider.
  #The above rake task arguments are optional, only if You want to add and remove metrices for perticular provider or perticuler provider and category or perticular services that time only it is necessary.
  task add_new_configs: :environment do
    desc 'Add account wise new default confiuration without migrating old configs'
    Account.all.each do |account|
      begin
        account.create_service_adviser_default_config
        CSLogger.info "====== Added new configs for account #{account.try(:name)}=========="
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
        next
      end
    end
  end

  task update_ignore_service_comments: :environment do
    desc 'Update service adviser ignore services comment to plain text'
    ServiceDetail.all.find_each do |service_detail|
      unless service_detail.comment.blank?
        comment = ActionView::Base.full_sanitizer.sanitize(service_detail.comment).strip
        service_detail.update(comment: comment)
      end
    end
    CSLogger.info "Updated service detais commmets to plain text."
  end

  task :update_new_configs, [:provider_type, :category, :service_type ] => [:environment] do |t, args|
    desc 'Update account wise new default confiuration'
    Account.all.each do |account|
      begin
        update_service_adviser_config(account, args.to_h)
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
        next
      end
    end
  end

  def migrate_old_aws_config(account)
    old_aws_config = ServiceAdviserConfiguration.find_by(account_id: account.id)
    return unless old_aws_config.present?

    new_aws_configs = account.service_adviser_configs.aws_configs.default_configs
    old_rightsize_configs = account.right_size_configuration
    new_aws_configs.each do |new_config|
      if new_config.category.eql?('idle')
        migrate_idle_configs(new_config, old_aws_config)
      elsif new_config.category.eql?('unoptimized')
        migrate_unoptimized_configs(new_config, old_aws_config, old_rightsize_configs)
      else
        migrate_general_configs(new_config, old_aws_config)
      end
    end
  end

  # for migrating SA unused/idle configs
  def migrate_idle_configs(new_config, old_aws_config)
    case new_config.service_type
    when 'ec2'
      new_config.config_details['idle_running_retention_period'] = old_aws_config.running_rightsizing_retention_period
      new_config.config_details['idle_stopped_retention_period'] = old_aws_config.stopped_rightsizing_retention_period
    when 'rds_snapshot'
      new_config.config_details['rds_snapshot_config_check'] = old_aws_config.rds_snapshot_config_check
      new_config.config_details['rds_snapshot_retention_period'] = old_aws_config.rds_snapshot_retention_period
    when 'volume_snapshot'
      new_config.config_details['volume_snapshot_config_check'] = old_aws_config.volume_snapshot_config_check
      new_config.config_details['volume_snapshot_retention_period'] = old_aws_config.volume_snapshot_retention_period
    when 'ami'
      new_config.config_details['ami_retention_period'] = old_aws_config.ami_retention_period if old_aws_config.ami_retention_period.present?
    end
    new_config.save
  end

  # for migrating SA rightsizing configs
  def migrate_unoptimized_configs(new_config, old_aws_config, old_rightsize_configs)
    case new_config.service_type
    when 'ec2'
      new_config.config_details['family_type'] = old_rightsize_configs.try(:family_type) || []
      new_config.config_details['right_size_config_check'] = old_rightsize_configs.try(:right_size_config_check)
      new_config.config_details['running_rightsizing_config_check'] = old_aws_config.running_rightsizing_config_check
      new_config.config_details['stopped_rightsizing_config_check'] = old_aws_config.stopped_rightsizing_config_check
    end
    new_config.save
  end

  # for migrating general SA configs
  def migrate_general_configs(new_config, old_aws_config)
    new_config.config_details['configurable_tag_key'] = old_aws_config.configurable_tag_key
     # need to find out the use case the below config
    new_config.config_details['service_type'] = old_aws_config.service_type if old_aws_config.service_type.present?
    new_config.save
  end

  def update_service_adviser_config(account, provider_type: nil, category: nil, service_type: nil)
    applicable_filters = {}.tap do |filter|
      filter[:category] = category if category.present?
      filter[:provider_type] = provider_type if provider_type.present?
      filter[:service_type] = service_type if service_type.present?
    end
    service_adviser_configs = account.service_adviser_configs.where(applicable_filters)
    CSLogger.info("===================== Record Not Found =====================") if service_adviser_configs.empty?

    service_adviser_configs.each do |service_adviser_config|
      CSLogger.info("===== Checking configuration for Account :#{account.try(:name)} Provider: #{service_adviser_config.provider_type} Service: #{service_adviser_config.service_type} =====")
      begin
        file_path = Rails.root.join('data/service_adviser_config').join("#{service_adviser_config.provider_type}/#{service_adviser_config.category}/#{service_adviser_config.service_type}.json")
        config_file = File.open file_path
        config_json = JSON.load config_file
        json_idle_conditions = config_json["idle_conditions"].nil? ? [] : config_json["idle_conditions"]
        existing_metrices = service_adviser_config.idle_conditions.nil? ? [] : service_adviser_config.idle_conditions
        add_new_metrices(existing_metrices, json_idle_conditions)
        remove_deleted_metrics(existing_metrices, json_idle_conditions)
        json_config_except_metrics = config_json.except('idle_conditions')
        existing_config_except_metrics = service_adviser_config.config_details.except('idle_conditions')
        new_config_except_metrics = add_and_remove_config_except_metrics(existing_config_except_metrics, json_config_except_metrics)
        service_adviser_config.config_details = if service_adviser_config.idle_conditions.nil?
          new_config_except_metrics
        else
          { 'idle_conditions': service_adviser_config.idle_conditions }.merge(new_config_except_metrics)
        end
        if service_adviser_config.changed?
          service_adviser_config.save
          CSLogger.info("===== Added new configs for Account :#{account.try(:name)} Provider: #{service_adviser_config.provider_type} Service: #{service_adviser_config.service_type} =====")
        end
      rescue StandardError => e
        CSLogger.error e.message
        CSLogger.error e.backtrace
      end
    end
  end

  def add_new_metrices(existing_metrices, json_metrices)
    new_metrices = json_metrices.reject { |json_config| existing_metrices.pluck('metric').include? json_config['metric'] }
    existing_metrices.concat(new_metrices)
  end

  def remove_deleted_metrics(existing_metrices, json_metrices)
    existing_metrices.reject! { |existing_config| !(json_metrices.pluck('metric').include? existing_config['metric']) }
  end

  def add_and_remove_config_except_metrics(existing_configs, json_configs)
    # remove
    existing_configs.reject! { |key, value| !(json_configs.keys.include? key) }
    # add
    new_configs = json_configs.reject { |key, value| existing_configs.keys.include? key }
    existing_configs.merge!(new_configs)
  end
end
