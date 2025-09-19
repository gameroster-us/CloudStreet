# frozen_string_literal: true

module Groups
  # Service Class to suppor group delete operation
  # And related tasks
  class Deleter < ServiceGroupService
    class << self
      def call(account, service_group_id, user, from_v2_api: false, &block)
        service_group = ServiceGroup.find(service_group_id)
        shared_tenant_ids = service_group.tenants.ids
        adapter_ids_to_remove = ServiceGroup.adapterids_from_adapter_group(service_group_id)
        shared_to_child_org = service_group.provider_type.eql?('VmWare') ? [] : get_shared_to_child_org_details(service_group_id, account.organisation)
        if service_group.destroy
          args = {
            account: account,
            user: user,
            service_group: service_group,
            adapter_ids_to_remove: adapter_ids_to_remove,
            shared_to_child_org: shared_to_child_org,
            tenant: service_group.tenant,
            shared_tenant_ids: shared_tenant_ids,
            from_v2_api: from_v2_api
          }
          perform_post_deletion_tasks(args)
          status Status, :success, { messages: 'Group deleted successfully' }, &block
        else
          status Status, :error, e, &block
        end
      rescue StandardError => e
        status Status, :error, e, &block
      end

      # Perform tasks related to Budget/child org/subtenant/report
      def perform_post_deletion_tasks(args)
        organisation_identifier = args[:account].organisation_identifier
        provider_type = args[:service_group].provider_type
        service_group_name = args[:service_group].name

        ::Groups::Updater.update_subtenant_groups(args[:tenant], args[:service_group].id, true, true)
        unshare_adapter_from_child_org(**args.slice(:account, :service_group, :adapter_ids_to_remove, :shared_to_child_org)) unless provider_type.eql?('VmWare')
        update_budget(**args.slice(:account, :user, :service_group, :adapter_ids_to_remove, :shared_tenant_ids, :shared_to_child_org))
        update_account_group_athena_table(organisation_identifier, provider_type, service_group_name, 'delete') unless args[:from_v2_api]
      end

      def unshare_adapter_from_child_org(account:, service_group:, adapter_ids_to_remove:, shared_to_child_org:)
        adapters_in_service_groups = {
          normal_adapters: adapter_ids_to_remove,
          billing_adapter: service_group.billing_adapter_id
        }

        ChildOrganisation::UnshareAdaptersOnGroupsDeletion.perform_async(account.organisation.id,
                                                                         adapters_in_service_groups,
                                                                         service_group.id,
                                                                         shared_to_child_org)
      end

      def update_budget(account:, user:, service_group:, adapter_ids_to_remove:, shared_tenant_ids:, shared_to_child_org:)
        group_hash = {
          id: service_group.id,
          name: service_group.name,
          provider_type: service_group.provider_type,
          adapter_ids_to_removed: adapter_ids_to_remove,
          shared_tenant_ids: shared_tenant_ids,
          own_tenant_id: [service_group.tenant_id],
          billing_adapter_id: service_group.billing_adapter_id,
          shared_to_child_org: shared_to_child_org
        }

        UpdateBudgetWorker.perform_async(group_hash, account.id, user.id, 'delete')
      end
    end
  end
end
