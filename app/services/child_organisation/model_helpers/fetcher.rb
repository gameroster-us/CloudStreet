# frozen_string_literal: true

# Helper methods for Fetcher
module ChildOrganisation::ModelHelpers::Fetcher

  # Instance level methods
  module InstanceMethods
    # Method to fetch organisations's shared adapter excluding adapter groups's included adapters
    def shared_adapters_to_org
      adapter_groups_adapter = ServiceGroup.adapterids_from_adapter_group(service_groups.ids)
      shared_adapters.where.not(id: adapter_groups_adapter).map do |a|
        {id: a.id, name: a.name, adapter_type: a.type.to_s.gsub('Adapters::', ''), adapter_purpose: a.adapter_purpose}
      end
    end

    def shared_service_groups_to_org
      service_groups.select(:id, :name, :type, :provider_type)
    end
  end

  module ClassMethods
    def normal_adapters_fetcher(current_tenant, params)
      billing_adapter_ids = params[:billing_adapter_id].split(',')
      billing_adapters = ::Adapter.where(id: billing_adapter_ids)
      all_normal_adapters = []
      billing_adapters.each do |billing_adapter|
        CurrentAccount.client_db = billing_adapter.account
        if billing_adapter.type.eql?("Adapters::AWS")
          aws_accounts = AWSAccountIds.where(adapter_id: billing_adapter.id).pluck(:aws_accounts).flatten.uniq
          aws_accounts = aws_accounts.map { |aws_acc| aws_acc&.rjust(12, '0') }
          normal_adapters = current_tenant.adapters.aws_adapter.normal_adapters.include_not_configured
          all_normal_adapters << normal_adapters.map do |adapter|
            adapter.id if aws_accounts.include? adapter.data['aws_account_id']
          end.compact
        elsif billing_adapter.type.eql?("Adapters::Azure")
          subscription_ids = AzureAccountIds.where(adapter_id: billing_adapter.id).pluck(:subscription_ids).flatten.uniq
          all_normal_adapters << current_tenant.adapters.azure_adapter.normal_adapters.include_not_configured.where("data->'subscription_id' in(?)", subscription_ids).ids
        elsif billing_adapter.type.eql?("Adapters::GCP")
          project_ids = GCPProjectIds.where(adapter_id: billing_adapter.id).distinct(:project_ids).flatten
          all_normal_adapters << current_tenant.adapters.gcp_adapter.normal_adapters.include_not_configured.where("data-> 'project_id' in(?)", project_ids).ids
        end
        Thread.current[:client_db] = 'api_default'
      end
      ::Adapter.where(id: all_normal_adapters.flatten)
    end

    def adapter_groups_fetcher(account, tenant, params)
      tenant_ids = tenant.is_default ? account.organisation.tenants.pluck(:id) : tenant.id
      service_groups = ServiceGroup.where(account_id: account.id, tenant_id: tenant_ids)
      service_groups = service_groups.where(billing_adapter_id: params[:billing_adapter_id].split(',')) if params[:billing_adapter_id].present?
    end

    def shared_adapters_to_other_child_orgs(parent_organisation, child_organisation_id)
      other_child_org_ids = parent_organisation.child_organisations.ids - [child_organisation_id]
      Organisation.where(id: other_child_org_ids).map { |org| org.adapters.normal_adapters}.flatten.pluck(:id)
    end

    def shared_groups_to_other_child_orgs(parent_organisation, child_organisation_id)
      other_child_org_ids = parent_organisation.child_organisations.ids - [child_organisation_id]
      OrganisationServiceGroup.where(organisation_id: other_child_org_ids).pluck(:service_group_id)
    end

    def store_version(billing_config)
      version_attrs = billing_config.attributes.except('_id', '_type', 'versions_count').tap do |version|
        version[:modifier_name] = billing_config.modifier_name
      end
      billing_config.versions.create!(version_attrs)
    end

    def can_destroy?(billing_config)
      current_month = Date.today.strftime('%Y-%m')
      config_created_month = billing_config.created_at.strftime('%Y-%m')
      config_created_month == current_month ||
      billing_config.margin_discount_hash.keys.none? { |month| month <= current_month }
    end
  end

  def self.included(receiver)
    receiver.extend ClassMethods
    receiver.send :include, InstanceMethods
  end
end
