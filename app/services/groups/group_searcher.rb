# frozen_string_literal: true

module Groups
  # Service Class for group view operation
  class GroupSearcher < CloudStreetService
    class << self
      def list(current_account, current_tenant, params)
        # This method currently not in use
        # we are using ServiceGroup.list method for the same task
        applicable_filters = { account_id: current_account.id, tenant_id: current_tenant.id }

        ServiceGroup.where(applicable_filters)
        service_groups, total_records = apply_pagination(service_groups, params)
        status Status, :success, [service_groups, total_records], &block
      end

      def find(); end

      def tag_list(); end

      # This methods returns
      # custom data present inside groups
      # for group filteration puspose
      def groups_custom_data(current_account, current_tenant, params, &block)
        tenant_ids = current_tenant.is_default ? current_account.organisation.tenants.pluck(:id) : current_tenant.id
        shared_group_ids_with_subtenant = current_tenant.service_groups.ids
        service_groups = ServiceGroup.where(account_id: current_account.id, tenant_id: tenant_ids, provider_type: params[:provider_type])
                                     .or(ServiceGroup.where(id: shared_group_ids_with_subtenant, provider_type: params[:provider_type]))
        custom_data_arr = service_groups.pluck(:custom_data)
        result = custom_data_arr.each_with_object({}) do |custom_data, memo|
          custom_data.each do |key, value|
            memo[key] ||= []
            memo[key] << value
          end
        end
        result.transform_values!(&:uniq)

        status Status, :success, result, &block
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def billing_adapter_groups(account, current_tenant, params, &block)
        tenant_ids = current_tenant.is_default ? account.organisation.tenants.pluck(:id) : current_tenant.id
        shared_group_ids_with_subtenant = current_tenant.service_groups.ids
        service_groups = ServiceGroup.non_empty_groups.where(account_id: account.id, tenant_id: tenant_ids)
                                     .or(ServiceGroup.non_empty_groups.where(id: shared_group_ids_with_subtenant))
        service_groups = service_groups.where(provider_type: params[:provider_type]) if params[:provider_type].present?
        service_groups = service_groups.where(billing_adapter_id: params[:billing_adapter_id]) if params[:billing_adapter_id].present?
        service_groups = service_groups.name_like(params[:name]) if params[:name].present?
        service_groups, total_records = apply_pagination(service_groups, params)
        service_groups = service_groups.order(:name)
        status Status, :success, [service_groups.select(:id, :name), total_records], &block
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def group_info(params, &block)
        service_group = ServiceGroup.find_by_id(params[:id])
        if service_group.present?
          status Status, :success, service_group, &block
        else
          status Status, :not_found, 'Service Group not found' , &block
        end
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def groups_account_tag_key_values(current_account, current_tenant, params, &block)
        raise(ActionController::ParameterMissing, :billing_adapter_id) if params[:billing_adapter_id].blank?

        tenant_ids = current_tenant.is_default ? current_account.organisation.tenants.pluck(:id) : current_tenant.id
        shared_group_ids_with_subtenant = current_tenant.service_groups.ids
        service_groups = ServiceGroup.where(account_id: current_account.id, tenant_id: tenant_ids)
                                     .or(ServiceGroup.where(id: shared_group_ids_with_subtenant))

        result = service_groups.where(billing_adapter_id: params[:billing_adapter_id])
                               .aws_groups
                               .pluck("data->>'aws_account_tag_key'", 'account_tag')
                               .group_by(&:first)
                               .transform_values { |a |a.map(&:last).uniq }

        status Status, :success, result, &block
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def get_groups_info_for_recommendation_policy(params, &block)
        return [] unless params[:adapter_group_ids].present? || params[:custom_data_keys]

        service_groups = ServiceGroup.where(id: params[:adapter_group_ids])
                                     .where("custom_data ?| ARRAY[:keys]", keys: params[:custom_data_keys])
        if service_groups.present?
          service_groups_info = []
          service_groups.each do |service_group|
            group_info_hash = {
              adapter_group_name: service_group&.name,
              custom_data_keys: params[:custom_data_keys] & service_group.custom_data.keys,
              custom_data_values: params[:custom_data_keys].map { |key| service_group.custom_data[key] }.compact
            }
            service_groups_info << group_info_hash
          end
          status Status, :success, service_groups_info, &block
        else
          status Status, :not_found, 'Custom data not found' , &block
        end
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def fetch_custom_data_keys(current_tenant, params, &block)
        raise(ActionController::ParameterMissing, :billing_adapter_id) if params[:billing_adapter_id].blank?

        tenant_ids = current_tenant.is_default? ? current_tenant.organisation.tenants.ids : current_tenant.id
        applicable_shared_group_ids = current_tenant.service_groups.where(billing_adapter_id: params[:billing_adapter_id])
        custom_data_keys = (ServiceGroup.where(tenant_id: tenant_ids, billing_adapter_id: params[:billing_adapter_id])
                                        .or(ServiceGroup.where(id: applicable_shared_group_ids)))
                                        .pluck(:custom_data).flatten
                                        .uniq.map(&:keys).flatten.uniq
        status Status, :success, custom_data_keys, &block
      rescue StandardError => error
        status Status, :error, error, &block
      end

      def fetch_custom_data_values(current_tenant, params, &block)
        raise(ActionController::ParameterMissing, :billing_adapter_id) if params[:billing_adapter_id].blank?

        raise(ActionController::ParameterMissing, :custom_data_key) if params[:custom_data_key].nil?

        tenant_ids = current_tenant.is_default? ? current_tenant.organisation.tenants.ids : current_tenant.id
        applicable_shared_group_ids = current_tenant.service_groups.where(billing_adapter_id: params[:billing_adapter_id])
        custom_data_values = (ServiceGroup.where(tenant_id: tenant_ids, billing_adapter_id: params[:billing_adapter_id])
                                        .or(ServiceGroup.where(id: applicable_shared_group_ids)))
                                        .where("custom_data != '{}'::JSONB")
                                        .pluck(:custom_data)
                                        .uniq.map { |custom_data| custom_data[params[:custom_data_key]]}.compact.uniq
        status Status, :success, custom_data_values, &block
      rescue StandardError => error
        status Status, :error, error, &block
      end

    end
  end
end
