class Adapters::Creators::AWS < CloudStreetService
  class << self

    def call(organisation, tenant, user, adapter, params, &block)
      # Commenting this method as not using iam inline policy any more.
      # adapter.add_or_update_iam_role_inline_policy if adapter.role_based?
      adapter.set_aws_account_id unless adapter.aws_account_id.present?

      if adapter.valid?
        unless params['role_arn'].blank?
          if CommonConstants::ROLE_ARNS.include?(params['role_arn'])
            status AdapterStatus, :auth_failure, 'Unable to create adapter with this credentials', &block
            return
          end
        end
        # unless adapter.verify_connections?(adapter.role_based? || false)
        #   # Commenting this method as not using iam inline policy any more.
        #   # adapter.remove_iam_role_inline_policy
        #   CloudStreetService.status AdapterStatus, :auth_failure, adapter.get_adapter_cred_error_msg, &block
        #   return adapter
        # end
        create_linked_adapters = {}
        if !params['role_name'].blank? && params[:adapter_purpose].eql?('billing')
          create_linked_adapters = fetch_organization_account(params)
          if create_linked_adapters[:error].present?
            CloudStreetService.status AdapterStatus, :auth_failure, create_linked_adapters[:error], &block
            return adapter
          end
        end
        CSLogger.info("Adapter is valid!")
        adapter.check_adapter_cloudtrail_status
        (adapter.try :set_aws_account_id unless adapter.aws_account_id.present?)
        if adapter.adapter_purpose.eql?("billing")
          adapter.aws_support_discount = params[:aws_support_discount]
          adapter.invoice_date = params[:invoice_date]
          adapter.enable_invoice_date = params[:enable_invoice_date]
          adapter.service_types_discount = params[:service_types_discount]
          adapter.aws_vat_percentage = params[:aws_vat_percentage]
          # for safer side we are setting linked adapter sts region to default!
          adapter.linked_adapter_sts_region = 'us-west-2' if adapter.linked_adapter_sts_region.nil?
        end

        adapter.create!
        organisation.original_adapters << adapter #mapping organisation and adapter via organisation_adapters
        adapter.activate!
        if adapter.adapter_purpose.eql?("billing")
          create_report_configuration(adapter,params)
          @feature = Flipper.feature($flipper_feature['aws_support_for_cardinality_based_query_feature'].to_sym)
          feature_enabled = @feature.enabled?(adapter.account.organisation)
          if feature_enabled && adapter.type.include?('AWS')
            ServiceGroupSetting.create_and_update_group_setting_configuration_aws(adapter, params[:service_tag_keys])
          else
            ServiceGroupSetting.create_and_update_group_setting_configuration(adapter, params[:service_tag_key])
          end
        end
        if create_linked_adapters[:aws_accounts].present? && create_linked_adapters[:aws_accounts].count > 0
          role_arns_for_linked_adapters = []
          create_linked_adapters[:aws_accounts].each do |aws_account|
            role_arns_for_linked_adapters << "arn:aws:iam::#{aws_account[:id]}:role/#{params[:role_name]}"
          end
          if role_arns_for_linked_adapters.any? { |role_arn| CommonConstants::ROLE_ARNS.include?(role_arn) }
            status AdapterStatus, :auth_failure, 'Unable to create adapter with this credentials', &block
            return
          end
          CreateLinkAdaptersWorker.perform_async(adapter.id,params,create_linked_adapters[:aws_accounts],organisation.id,user.id,tenant.id)
        end
        tenant.original_adapters << adapter if tenant.present? && !tenant.is_default
        # FollowUpEmail.check_and_inactive_followup_if_any(user.id,account.id,"NO-SCHEDULED_SYNC")
        assign_billing_adapter(params[:billing_adapter],adapter) if params[:adapter_purpose] == 'normal'
        adapter.preferred_backup_region_id = params[:preferred_backup_region_id] if params[:adapter_purpose] == 'backup'
        create_bucket(adapter,params,user) unless params[:bucket_id].blank?
        adapter.perform_sync_task if params[:adapter_purpose] == 'normal'
        adapter.perform_post_update_tasks
        adapter.fetch_private_ami if params[:adapter_purpose] == 'normal'
        if params[:adapter_purpose].eql?('billing') || params[:adapter_purpose].eql?('normal')
          adapter.update_mongoid_yml
          adapter.trigger_report_api
        end

        if adapter.billing?
          organisation.get_default_tenant.set_default_billing_adapter(adapter) unless organisation.is_default_tenant?(tenant)
          tenant.set_default_billing_adapter(adapter)
        end

        CloudStreetService.status AdapterStatus, :success, AdapterInfo.new(adapter), &block
        return adapter
      else
        CSLogger.info "Invalid adapter details!"
        CSLogger.info adapter.inspect
        CSLogger.error adapter.errors.inspect
        status AdapterStatus, :validation_error, adapter, &block
        return adapter
      end
    end

    def assign_billing_adapter(billing_adapter_id,adapter)
      unless billing_adapter_id.blank?
        parent = Adapter.find(billing_adapter_id)
        adapter.update :parent => parent
      end
    end

    def create_bucket(adapter,params,user)
      adapter.bucket_id        = params[:bucket_id]
      adapter.bucket_region_id = params[:bucket_region_id] || params[:region_id]
      adapter.user = user  
      Storages::AWS.create(:region_id => params[:bucket_region_id], :key => params[:bucket_id], :account => adapter.account, :adapter => adapter, :creation_date => Time.now)
      adapter.save! 
    end

    def create_report_configuration(adapter, params)
      begin
        params[:report_configuration].each do |config_params|
          report_configuration = adapter.report_configurations.new(config_params)
          if report_configuration.save
            CSLogger.info "ReportConfiguration with id #{report_configuration.id} saved successfully."
          else
            CSLogger.error "Failed to save ReportConfiguration: #{report_configuration.errors.full_messages.join(', ')}"
          end
        end
      rescue StandardError => e
        CSLogger.error "Error in creating config = #{e.message}"
        CSLogger.error e.backtrace
        Honeybadger.notify(e, error_class: 'AWSReportConfig::CreateConfig', error_message: "Error in creating config = #{e.message}", parameters: { adapter_id: adapter.id }) if ENV['HONEYBADGER_API_KEY']
      end
    end

    def fetch_organization_account(params)
      organisation_client = set_adapter_details(params,"AWSSdkWrappers::Organizations::Client")
      AdapterSearcher.fetch_organization_account(params, organisation_client)
    end

     def set_adapter_details(params,aws_sdk_Wrappers_name)
      if params[:adapter_id]
        adapter = Adapter.find_by(id: params[:adapter_id])
        if params[:role_based]
          params[:role_arn] = adapter.role_arn
        else
          params[:access_key_id] = adapter.access_key_id
          params[:secret_access_key] = adapter.secret_access_key
        end
      end
      adapter = Adapters::AWS.directoried.first.dup
      if params[:role_based]
        options = {
          use_instance_profile: true,
          cross_acc_role_arn: params[:role_arn],
          external_id: params[:external_id]
        }
        adapter.role_based = true
        adapter.role_arn = params[:role_arn]
        adapter.aws_account_id = params[:aws_account_id]
        # Commenting this method as not using iam inline policy any more.
        # adapter.add_or_update_iam_role_inline_policy
        # sleep(8)
        return aws_sdk_Wrappers_name.constantize.new(nil,'us-east-1',options).client
      else
        adapter.access_key_id = params[:access_key_id]
        adapter.secret_access_key = params[:secret_access_key]
        return aws_sdk_Wrappers_name.constantize.new(adapter,'us-east-1').client
      end
    end

  end
end
