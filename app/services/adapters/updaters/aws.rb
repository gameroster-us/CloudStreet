class Adapters::Updaters::AWS < CloudStreetService
  class << self

    def call(user, tenant, adapter, params, &block)
      params[:role_name] = nil if params[:role_name].blank?
      old_adapter_credential = adapter.role_based? ? adapter.data["role_arn"] : adapter.data["access_key_id"]
      old_adapter_state = adapter.state
      old_adapter_role = adapter.role_based?
      remove_policy = nil
      # for safer side we are setting linked adapter sts region to default!
      params[:linked_adapter_sts_region] = 'us-west-2' if params[:adapter_purpose].eql?('billing') && params[:linked_adapter_sts_region].nil?
      if adapter.role_based? && !adapter.state.eql?('not_configured')
        if (adapter.role_arn != params[:role_arn]) || params[:role_arn].blank?
          remove_policy = "cross-account-#{adapter.aws_account_id}-#{adapter.role_arn[/role\/(.*)/,1]}" unless Adapters::AWS.where("data @> hstore(:key, :value)", key: 'role_arn' ,value: adapter.role_arn).available.count > 1
        end
      end
      adapter.assign_attributes(parsed_params(params).except('billing_adapter', 'report_configuration'))

      if adapter.role_based?
        # Commenting this method as not using iam inline policy any more.
        # adapter.add_or_update_iam_role_inline_policy
        adapter.external_id = params["external_id"]
        adapter.access_key_id = nil
        adapter.secret_access_key = nil
        adapter.aws_session_token = nil
        adapter.token_expiration = nil
      else
        adapter.aws_account_id = nil
        adapter.role_arn = nil
        adapter.aws_session_token = nil
        adapter.token_expiration = nil
      end
      adapter.try :set_aws_account_id

      if adapter.valid?
        unless params['role_arn'].blank?
          if CommonConstants::ROLE_ARNS.include?(params['role_arn'])
            status AdapterStatus, :auth_failure, 'Unable to create adapter with this credentials', &block
            return
          end
        end
        # unless adapter.verify_connections?
        #   # Commenting this method as not using iam inline policy any more.
        #   # adapter.remove_iam_role_inline_policy
        #   status AdapterStatus, :auth_failure, adapter.get_adapter_cred_error_msg, &block
        #   return adapter
        # end

        adapter.state = 'active'
        if adapter.is_aws? && params[:adapter_purpose].eql?('billing')
          adapter.aws_support_discount = params[:aws_support_discount]
          adapter.service_types_discount = params[:service_types_discount]
          adapter.aws_vat_percentage = params[:aws_vat_percentage]
          adapter.invoice_date = params[:invoice_date]
          adapter.enable_invoice_date = params[:enable_invoice_date]
        end
        adapter.save
        adapter.trigger_report_api(adapter.previous_changes) if adapter.is_aws? && params[:adapter_purpose].eql?('billing')
        create_linked_adapters = {}
        if adapter.is_aws? && !params['role_name'].blank? && params[:adapter_purpose].eql?('billing')
          create_linked_adapters = fetch_organization_account(params.merge(adapter_id: adapter.id))
          if create_linked_adapters[:error].present?
            CloudStreetService.status AdapterStatus, :auth_failure, create_linked_adapters[:error], &block
            return adapter
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
          org = adapter.account.organisation
          CreateLinkAdaptersWorker.perform_async(adapter.id,parsed_params(params),create_linked_adapters[:aws_accounts],org.id,user.id)
        end

        run_sync = false
        if params[:adapter_purpose] == 'normal' && !adapter.sync_running
          if !old_adapter_state.eql?(adapter.state) || !old_adapter_role.eql?(adapter.role_based?)
            run_sync = true
          else
            new_adapter_credential = adapter.role_based? ? adapter.data["role_arn"] : adapter.data["access_key_id"]
            run_sync = true if !old_adapter_credential.eql?(new_adapter_credential)
          end
        end
        adapter.update_adapter_group
        adapter.perform_sync_task if run_sync
        remove_role_policy(remove_policy) unless remove_policy.blank?
        update_billing_adapter(params[:billing_adapter],adapter)
        update_bucket(adapter,params,user) if !params[:bucket_id].blank? && adapter.is_aws?
        adapter.perform_post_update_tasks
        if adapter.adapter_purpose.eql?("billing")
          update_report_configuration(adapter,params)
          @feature = Flipper.feature($flipper_feature['aws_support_for_cardinality_based_query_feature'].to_sym)
          feature_enabled = @feature.enabled?(adapter.account.organisation)
          if feature_enabled && adapter.type.include?('AWS')
            ServiceGroupSetting.create_and_update_group_setting_configuration_aws(adapter, params[:service_tag_keys])
          else
            ServiceGroupSetting.create_and_update_group_setting_configuration(adapter, params[:service_tag_key])
          end
        end
        CloudStreetService.status AdapterStatus, :success, AdapterInfo.new(adapter), &block
        return adapter
      else
        CSLogger.error "Invalid adapter details!"
        CSLogger.info adapter.inspect
        CSLogger.error adapter.errors.inspect
        status AdapterStatus, :validation_error, adapter, &block
        return adapter
      end

    end

    def update_report_configuration(adapter, params)
      report_configs = []
      params[:report_configuration].each do |config_params|
        begin
          report_config = adapter.report_configurations.find_or_initialize_by(id: config_params[:id])
          report_config.assign_attributes(config_params)
          report_config.save!
          report_configs << report_config
        rescue StandardError => e
          CSLogger.error "Error in Updating config = #{e.message}"
          CSLogger.error e.backtrace
          Honeybadger.notify(e, error_class: 'AWSReportConfig::UpdateConfig', error_message: "Error in updating config = #{e.message}", parameters: { adapter_id: adapter.id, report_config_id: config_params[:id] }) if ENV['HONEYBADGER_API_KEY']
        end
      end

      report_configs
    end


    def remove_role_policy(remove_policy)
      instance_profile_role = InstanceProfileService.get_instance_profile_role
      return if instance_profile_role.blank?
      iam = Fog::AWS::IAM.new(:use_iam_profile => true, :region => 'us-east-1')
      iam.delete_role_policy(instance_profile_role,remove_policy)
    rescue Fog::AWS::IAM::NotFound => e
      CSLogger.error e.message
    end

    def update_billing_adapter(billing_adapter_id,adapter)
      unless billing_adapter_id.blank?
        parent = Adapter.find(billing_adapter_id)
        adapter.update :parent => parent
        adapter.update :bucket_id => nil
      else
        adapter.update :parent => nil
      end
    end

    def update_bucket(adapter,params,user)
      adapter.bucket_id  = (params[:billing_adapter] && params[:billing_adapter].present?) ? nil : params[:bucket_id]
      adapter.bucket_region_id = params[:bucket_region_id] || params[:region_id]
      adapter.save!
    end

    def update_bucket_id(adapter, params, user, &block)
      adapter.bucket_id        = params[:adapter][:bucket_id]
      adapter.bucket_region_id = params[:adapter][:region_id]
      adapter.user = user
      test_result = adapter.verify_bucket_id
      if test_result[:result] && params[:is_bucket_for_reports]
        adapter.save!
        status AdapterStatus, :success, adapter, &block
      else
        status AdapterStatus, :validation_error, error_type: test_result[:error], &block
      end
    end

    def refetch_buckets(adapter_id, &block)
      adapter = fetch Adapter, adapter_id
      StorageManager.synchronize_buckets(adapter)
      status AdapterStatus, :success, AdapterInfo.new(adapter), &block
    end

    def fetch_organization_account(params, &block)
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
      if params[:role_based]
        options = {
          use_instance_profile: true,
          cross_acc_role_arn: params[:role_arn],
          external_id: params[:external_id]
        }
        return aws_sdk_Wrappers_name.constantize.new(nil,'us-east-1',options).client
      else
        adapter = Adapters::AWS.directoried.first
        adapter = adapter.dup
        adapter.access_key_id = params[:access_key_id]
        adapter.secret_access_key = params[:secret_access_key]
        return aws_sdk_Wrappers_name.constantize.new(adapter,'us-east-1').client
      end

    end

    private

    def parsed_params(params)
      params = params.to_h || {}
      params.inject({}) do |hash, (attr_name, attr_val)|
        next(hash) if attr_val == "" && attr_name!='aws_account_id'
        hash[attr_name] =
        if attr_val.is_a?(ActionDispatch::Http::UploadedFile)
          attr_val.read
        else
          attr_val
        end
        hash
      end
    end

  end
end
