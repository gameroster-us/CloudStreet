module Api
  module V2
    module Concerns
      module ParamsValidator

        extend ActiveSupport::Concern
        include Api::V2::Concerns::ErrorMessage

        attr_accessor :adapter, :organisation
        MARGIN_DISCOUNT_CALCULATION = {
          'AWS'=> {unblended: 'line_item_unblended_cost', customer_cost: 'customer_cost'},
          'Azure'=> {cost: 'pre_tax_cost', customer_cost: 'customer_cost'},
          'GCP'=> {cost: 'cost', customer_cost: 'customer_cost'}
        }.freeze

        def adapter_name_valid
          return render json: { message: "Please enter an adapter name that is from 1 to 50 characters long." }, status: 422 unless params[:name].present? && params[:name].to_s.length <= 50

          return render json: { message: 'Please enter valid adapter name that contained valid characters.' }, status: 422 unless params[:name].match?(/^(?!\s)[\u0020-\u007E]+$/)
        end

        def aws_account_id_valid
          if params[:role_based]
            return render json: { message: "Please Enter Valid AWS Account ID." }, status: 422 unless params[:aws_account_id].to_i.to_s.eql?(params[:aws_account_id]) &&  params[:aws_account_id].to_i.to_s.length.eql?(12) && params[:aws_account_id].present?

            return render json: { message: "Please Enter Valid Role arn." }, status: 422 unless params[:role_arn].present? && params[:role_arn]&.tr("^0-9","").to_i.to_s.length.eql?(12)
          end
        end

        def check_billing_adapter_sts_region
          params[:sts_region]  = 'us-east-1' if params[:role_based]
          region = Region.enabled_by_account(true, current_account.id).aws.pluck(:id, :code)
          grouped_regions = region.group_by(&:pop).transform_values(&:flatten)
          region_id = grouped_regions[params[:linked_adapter_sts_region]].try(:last)
          return render json: { message: 'Linked adapter STS Region not exist' }, status: 500 if region_id.blank?

          params[:preferred_backup_region_id] = region_id
        end

        def check_bucket
          feature_manual_report_enabled = feature_enabled?($flipper_feature['aws_manual_export_report_configuration_feature'].to_sym)
          feature_multiple_report_enabled = feature_enabled?($flipper_feature['aws_billing_multiple_report_config_feature'].to_sym)
          params[:type] = "Adapters::AWS"
          params[:role_based] = params[:role_arn].present? ? true : false
          if feature_manual_report_enabled
            verify_aws_manual_config_feature
          elsif feature_multiple_report_enabled
            verify_aws_multiple_config_feature
          else
            params[:default_config] = true
            report_name = AdapterCreator.get_report_names(params, current_account)
            return render json: { message: report_name }, status: 422 unless report_name.is_a?Array

            report_name = report_name.select{|report| report[:s3_bucket].eql?(params[:bucket_id]) && report[:report_name].eql?(params[:report_name]) }
            return render json: { message: "Please provide valid bucket id." }, status: 422 if report_name.blank?

            report_name = existing_adapter_report_configuration(report_name) if params[:id].present?
            params[:report_configuration] = [report_name.first.merge(status: true)]
            CSLogger.info "Final Report Config: #{params[:report_configuration]}"
          end
        end

        def existing_adapter_report_configuration(report_names)
          report_config = adapter.report_configurations.destroy_all
          report_names
        end

        def get_tenant_adapter
          if params[:id].present?
            @adapter = current_tenant.adapters.aws_adapter.find_by_id(params[:id])
            return render json: { message: "Couldn't find Adapter with id=#{params[:id]}." }, status: 404 unless @adapter.present?
          end
        end

        def get_sts_region
          render json: { message: 'Region not exist' }, status: 500 if !['us-gov-east-1', 'us-gov-west-1'].include?(params[:sts_region]) && params[:role_based] && params[:is_us_gov]

          region = Region.enabled_by_account(true, current_account.id).aws.pluck(:code)
          return render json: { message: 'STS Region not exist' }, status: 500 if params[:role_based] && !params[:is_us_gov] && params[:sts_region].present? && !region.include?(params[:sts_region])

          params[:sts_region] = 'us-west-2' if params[:role_based] && !params[:is_us_gov] && !params[:sts_region].present?
        end

        def valid_aws_adapter
          if params[:adapter_id].present? && !params[:adapter_id].eql?('all')
            adapter = Adapters::AWS.find_by(id: params[:adapter_id])
            return render json: { message: "Couldn't find Adapter with id=#{params[:adapter_id]}" }, status: 404 unless adapter.present?
          end
        end

        def valid_aws_adapter_group
          if params[:adapter_group_id].present?
            service_group = ServiceGroup.find_by(id: params[:adapter_group_id], provider_type: 'AWS')
            return render json: { message: "ServiceGroup doesn't exist" }, status: 404 unless service_group.present?
          end
        end

        # def valid_aws_adapter_from_adapter_group
        #   params[:adapter_id] = ServiceAdviser::Base.fetch_normal_adapter_ids(current_tenant, 'Adapters::AWS', params[:adapter_id], params[:adapter_group_id])
        #   return render json: { message: "No adapter found or no adapter matched from adapter group"}, status: 404 unless params[:adapter_id].present?
        # end

        def validate_sub_account_ids
          return render json: {message: "Please provide at least one sub accounts ids."}, status: 422 if params[:sub_account_ids].blank?

          sub_accounts = AdapterSearcher.fetch_subaccounts(current_account, current_tenant, billing_adapter_id: params[:billing_adapter_id]).pluck(:id)
          invalid_sub_accounts = (params[:sub_account_ids] & sub_accounts).blank?
          return render json: {message: "Please provide valid sub accounts ids."}, status: 422 if invalid_sub_accounts
        end

        def validate_vcenter_ids
          return if params[:vcenter_ids].blank?

          vcenter_ids = VwVcenterService.fetch_vcenters(current_account, current_tenant, params).pluck(:id)
          return invalid_params('vcenter_ids') if (params[:vcenter_ids] - vcenter_ids).present?
        end

        def valid_margin_discount
          type = params['type'].split('::').last
          if type.eql?('Azure')
            return ['ss', 'ea'].include?(params[:azure_account_type])

          end
          margin_discount_calculation = MARGIN_DISCOUNT_CALCULATION[type][params['margin_discount_calculation'].try(:to_sym)]
          return render json: { message: "Please provide valid margin_discount_calculation." }, status: 422 if margin_discount_calculation.nil?

          params[:margin_discount_calculation] = margin_discount_calculation
        end

        def verify_aws_multiple_config_feature
          if params[:report_configuration].any? { |report| report.key?('bucket_id') }
            params[:default_config] = true
            result = AdapterCreator.get_report_names(params, current_account)
            selected_default_configs = params[:report_configuration].select { |report| !report.has_key?('default_config') }
            default_config_reports = check_valid_report_and_bucket(result, selected_default_configs, true) || []
            CSLogger.info "Default Configs =====#{default_config_reports}======"
            return render json: { message: result }, status: 422 if default_config_reports.blank?
          end
          sub_config_report_details = []
          params[:report_configuration].each do |report|
            if report.has_key?(:default_config)
              role_params = {}
              role_params[:default_config] = report[:default_config]
              role_params[:role_arn] = report[:role_arn]
              role_params[:role_based] = true
              role_params = role_params.with_indifferent_access
              sub_config_reports = if params[:role_arn].eql?(report[:role_arn])
                                     result
                                    else
                                      AdapterCreator.get_report_names(role_params, current_account)
                                    end
              next unless sub_config_reports.is_a?Array
              sub_config_reports = check_valid_report_and_bucket(sub_config_reports, report, false)
              CSLogger.info "Sub Report Configs Based on Role ARN===== Role Arn: #{report[:role_arn]}, Sub Configs: #{sub_config_reports}======"
              sub_config_report_details.concat(sub_config_reports) unless sub_config_reports.blank?
            end
          end
          combined_reports = (default_config_reports + sub_config_report_details).uniq
          return render json: { message: "The compression type must be consistent across the default and sub report configurations." }, status: 422 if combined_reports.pluck(:compression_type).uniq.count > 1

          combined_reports = existing_adapter_report_configuration(combined_reports) if params[:id].present?
          params[:report_configuration] = combined_reports.map { |report| report.merge(status: true) }
          CSLogger.info "Final Report Config for Feature Flag: #{params[:report_configuration]}"
        end

        def verify_aws_manual_config_feature
          default_config = params[:report_configuration].select { |report| !report.has_key?('default_config') } || []
          return render json: { message: "Please Enter the all fields report_name, report_prefix, compression_type for default config" }, status: 422 unless check_keys_of_default_config(default_config.first)

          sub_configs = params[:report_configuration].select { |report| report.has_key?('default_config') } || []
          sub_configs_reports = valid_report_configs(sub_configs, params, default_config.first)
          combined_reports = (default_config + sub_configs_reports).uniq
          combined_reports = existing_adapter_report_configuration(combined_reports) if params[:id].present?
          params[:report_configuration] = combined_reports.map { |report| report.merge(status: true) }
          CSLogger.info "Feature AWS Manual Reports: #{params[:report_configuration]}"
        end

        def valid_report_configs(report_configs, params, default_config)
          compression_type = default_config[:compression_type]
          region = Region.find_by(code: params[:region_name])
          filtered_report_configs = report_configs.map do |report|
            if report.has_key?(:default_config)
              report[:bucket_name] = params[:bucket_id]
              report[:bucket_region] = region.region_name
              report[:compression_type] = compression_type
              report
            end
          end
          filtered_report_configs
        end

        def check_valid_report_and_bucket(configs, report_configs_params, is_default_config)
          unless is_default_config
            report_names = report_configs_params[:report_name]
            role_arn = report_configs_params[:role_arn]
            report_names_to_filters = configs.select { |report| report_names.eql?(report[:report_name]) }
            append_role_arn_configs = report_names_to_filters.map { |config| config.merge(default_config: false, role_arn: role_arn) }
            filtered_report_configs = append_role_arn_configs.map { |report| report.transform_keys { |key| key == :s3_bucket ? :bucket_name : key == :s3_region ? :bucket_region : key } }
          else
            report_names_to_filter = report_configs_params.map { |config| config[:report_name] }
            filtered_report_configs = configs.select { |report| report_names_to_filter.include?(report[:report_name]) }
          end
          filtered_report_configs
        end

        def feature_enabled?(feature_name)
          return false unless current_account.present?

          feature = Flipper.feature(feature_name)
          feature.enabled?(current_account.organisation)
        end

        def check_keys_of_default_config(default_config)
         (default_config.keys == %w[report_name report_prefix compression_type]) && default_config.values.all?(&:present?)
        end

        def verify_credential_for_feature
          response = Adapters::CredentialVerifier.call(credential_verifier_params)
        end

        def validate_role_name
          if params[:role_name].present? && params[:account_setup].eql?('Yes')
            return render json: { message: "Invalid role name. Please ensure it is 1 to 64 characters long and can include letters, digits, or the symbols: + = , . @ -" }, status: 422 unless params[:role_name].match?(/\A[a-zA-Z0-9+=,.@-]{1,64}\z/)
          end
        end

        def validate_invoice_date
          if params[:invoice_date_setup].eql?('Yes')
            return render json: { message: 'Please Provide a Invoice Date'}, status: 422 if params[:invoice_date].blank?

            params[:enable_invoice_date] = true
            invoice_date = params[:invoice_date]
            if invoice_date.present? && !invoice_date.match?(/\A(0[1-9]|[12][0-9]|31)\z/)
              return render json: { message: 'Invoice date must be between 01 and 31' }, status: 422
            end
            params[:invoice_date] = invoice_date
          else
            params[:enable_invoice_date] = false
            params[:invoice_date] = nil
          end
        end

        def validate_edp
          if params[:aws_edp_setup].eql?('Yes')
            service_types_discount = params[:service_types_discount] || {}
            service_keys_valid = service_types_discount.keys.all? {|service| CommonConstants::AWS_SERVICES.include?(service)}
            return render json: { message: I18n.t('messages.valid_services_keys') }, status: 422 unless service_keys_valid

            service_discount_valid = service_types_discount.values.all? { |value| value.is_a?(Numeric) && value > 1 && value < 100 }
            return render json: { message: I18n.t('messages.discount') }, status: 422 unless service_discount_valid
          else
            params[:aws_support_discount] = nil
            params[:aws_vat_percentage] = nil
            params[:service_types_discount] = nil
          end
        end

        def set_report_profile_database
          CurrentAccount.client_db = current_account
          return render json: { message: "Client database is not set up correctly. Please ensure it is set to 'default'." }, status: 422 if CurrentAccount.client_db.eql?('default')
        end

        def check_adapter_status
          processed_adapters_status = UserSearcher.is_processed_adapter_present(current_tenant)
          return render json: { message: "No processed adapters are available. Please check your configurations or add an adapter." }, status: 422 unless processed_adapters_status.values.any?
        end

        def check_report_profile_valid
          unless ReportProfile.where(id: params[:id]).exists?
            return render json: { message: "Invalid Report Profile ID provided. Please ensure the ID corresponds to an existing report profile." }, status: 422
          end
        end

        def validate_report_profile_association
          if current_organisation.tenants.where(report_profile_id: params[:id]).exists?
            return render json: { message: "Unable to delete this report profile because it is currently associated with one or more tenants." }, status: 422
          end
        end

        def validate_default_currency
          return unless params[:enable_currency_conversion] && params[:default_currency].present?

          currency_configuration = current_organisation.currency_configurations.find_by_default_currency params[:default_currency]
          return render json: { message: "Please provide valid default currency." }, status: 404 unless currency_configuration
        end

        def adapter_validation
          ::V2::Swagger::Constants::CLOUD_PROVIDERS.each do |provider|
            adapters = params["#{provider.to_s.downcase}_adapters"]
            adapter_ids = "Adapters::#{provider.to_s}".constantize.ids
            if adapters.is_a?(Array) && adapters.present?
              adapters.each do |adapter|
                return render json: { message: "Invalid #{provider.to_s} adapter id = #{adapter}" }, status: 404 unless adapter_ids.include?(adapter)
              end
            elsif !adapters.eql?('All') && adapters.is_a?(String)
              return render json: { message: "Invalid #{provider.to_s} adapter id = #{adapters}" }, status: 404 unless adapter_ids.include?(adapters)
            end
          end
        end

        def tenant_name_valid
          return render json: { message: "Invalid name! Please ensure it starts with a letter or number and does not contain special characters, except for hyphens and underscores." }, status: 422 unless params[:name].match?(/^([a-zA-Z0-9])[a-zA-Z0-9-_]*$/)
        end

        def validate_tenant
          return if params[:id].nil?

          tenant = Tenant.find_by(id: params[:id])
          return render json: { message: "Couldn't find Tenant with id=#{params[:id]}" }, status: 404 unless tenant
        end

        def validate_adapter_group
          return if params[:selected_adapter_group].blank?

          valida_account_group_ids = current_account.service_groups.ids
          invalida_adapter_groups = params[:selected_adapter_group] - valida_account_group_ids
          return invalid_params('Adapter Group IDS') if invalida_adapter_groups.present?
        end

        def validate_resource_group
          return if params[:selectedResourceGroups].blank? || (params[:azure_adapters].blank? || params[:azure_adapters].eql?('All'))

          adapter_groups = ServiceGroup.where(id: params[:selected_adapter_group])
          adapter_ids = params[:azure_adapters] + ServiceGroup.adapterids_from_adapter_group(adapter_groups.ids)
          valid_resource_groups_ids = params[:selectedResourceGroups] & ::Azure::ResourceGroup.where(adapter_id: adapter_ids).active.order_by_name.ids
          return render json: { message: "Please provide valid Resource Groups for the selected adapters or adapter groups." }, status: 422 if valid_resource_groups_ids.blank?
        end

        def check_token_expires
          return render json: { message: I18n.t('messages.description') }, status: 422 if params[:description].blank?

          return render json: { message: I18n.t('messages.token_expires') }, status: 422 if params[:token_expires].blank?

          if params[:token_expires].present?
           return render json: { message: I18n.t('messages.valid_token_expires') }, status: 422 unless [0, 1, 2].include?(params[:token_expires])
          end
        end

        def validate_app_access_secret
          return if params[:id].nil?

          @app_access_secret = AppAccessSecret.find_by(id: params[:id])
          return render json: { message: I18n.t('messages.record_not_found', id: params[:id]) }, status: 404 unless @app_access_secret
        end

        def check_enable_disable
          desired_state = params[:enabled] == true
          message = desired_state ? 'Disabled' : 'Enabled'
          if desired_state != @app_access_secret.enabled
            return render json: { message: I18n.t('messages.enable_disable', message: message) }, status: 422
          end
        end

        def validate_organisation_purpose
          return params.delete(:organisation_purpose) if current_organisation.organisation_purpose.nil?

          return invalid_params('organisation purpose') if !(::V2::Swagger::Constants::ORGANISATION_PURPOSE.include?(params[:organisation_purpose])) || params[:organisation_purpose].is_a?(Array) || params[:organisation_purpose].is_a?(Hash)
        end

        def validate_organisation_id
          @organisation = current_organisation.child_organisations.find_by(id: params[:id])
          return invalid_params('organisation id') if organisation.nil?
        end

        def validate_subdomain
          return invalid_params('subdomain') if params[:subdomain].blank?

          subdomain_exist = Organisation::Searcher.check_register_subdomain(subdomain: params[:subdomain])
          return subdomain_already_exist unless subdomain_exist.nil?
        end

        def validate_owner_type
          return invalid_params('owner type') if !(::V2::Swagger::Constants::OWNER_TYPE.include?(params[:ownerType])) || params[:ownerType].is_a?(Array) || params[:ownerType].is_a?(Hash)
        end

        def valid_report_profile_id
          set_report_profile_database
          return invalid_params('report profile id') unless ReportProfile.where(id: params[:report_profile_id]).exists?
        end

        def set_report_profile_database
          account = current_organisation.parent_organisation? ? current_organisation.try(:account) : current_organisation.parent_organisation.try(:account)
          CurrentAccount.client_db = account
        end

        def validate_email_and_user_id
          if params[:ownerType].eql?('create_new')
            return invalid_params('email') unless params[:email].match?(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i)
          else
            return invalid_params('existing user id') if params[:existing_user_id].blank?
            available_ids = Organisation::Searcher.get_organisation_active_users(current_organisation.id).ids
            return invalid_params('existing user id') unless available_ids.include?(params[:existing_user_id])

            if params[:ownerType].eql?('select_existing')
              available_ids -= [current_organisation.owner.id]
              return invalid_params('existing user id') unless available_ids.include?(params[:existing_user_id])
            else
              return invalid_params('existing user id') unless params[:existing_user_id].eql?(current_organisation.owner.id)
            end
          end
        end

        def valid_billing_adapters
          return if params[:billing_adapter_ids].blank?

          invalid_ids = params[:billing_adapter_ids] - available_billing_adapters.ids
          return invalid_params('billing adapter ids') if invalid_ids.present?
        end

        def validate_group_ids
          return if params[:adapter_group_ids].blank?

          return invalid_params('billing adapter ids') if params[:billing_adapter_ids].blank?

          available_group_ids = current_account.service_groups.ids
          invalida_ids = params[:adapter_group_ids] - available_group_ids
          return invalid_params('Adapter Group IDS') if invalida_ids.present?
        end

        def available_billing_adapters
          current_tenant_adapters.billing_adapters.available
        end

        def current_tenant_adapters
          current_tenant.adapters
        end

        def validate_azure_office_365_services
          office_services_ids = AzureOffice365Service.where(id: params[:azure_office_365_services]).pluck(:id)
          params[:azure_office_365_services] - office_services_ids
        end

        def validate_normal_adapter_ids
          return if params[:normal_adapters_ids].blank?
          return invalid_params('billing adapter ids') if params[:billing_adapter_ids].blank?

          billing_adapters = Adapter.where(id: params[:billing_adapter_ids])
          associated_normal_adapter_ids = []
          normal_adapters = current_tenant.adapters.include_not_configured.normal_adapters
          billing_adapters.each do |billing_adapter|
            CurrentAccount.client_db = billing_adapter.account
            case billing_adapter.type
            when "Adapters::AWS"
              aws_accounts = AWSAccountIds.where(adapter_id: billing_adapter.id).pluck(:aws_accounts).flatten
              associated_normal_adapter_ids += normal_adapters.aws_adapter.where("data->'aws_account_id' IN (?)", aws_accounts).ids
            when "Adapters::Azure"
              subscription_ids = AzureAccountIds.where(adapter_id: billing_adapter.id).pluck(:subscription_ids).flatten
              associated_normal_adapter_ids += normal_adapters.azure_adapter.where("data->'subscription_id' IN (?)", subscription_ids).ids
            when "Adapters::GCP"
              project_ids = GCPProjectIds.where(adapter_id: billing_adapter.id).pluck(:project_ids).flatten
              associated_normal_adapter_ids += normal_adapters.gcp_adapter.where("data->'project_id' IN (?)", project_ids).ids
            end
          end
          invalida_ids = params[:normal_adapters_ids] - associated_normal_adapter_ids.uniq
          return invalid_params('normal adapter IDS') if invalida_ids.present?
        end
      end
    end
  end
end
