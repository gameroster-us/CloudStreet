# frozen_string_literal: false
# rake service_group:update_empty_adapter_group_flag
# rake service_group:clean_deprecated_groups
# rake service_group:migrate_old_to_new
# rake service_group:update_gcp_service_groups
# rake service_group:update_aws_group_as_all_selected
# rake service_group:apply_validation_to_existing_groups
# rake service_group:mark_azure_ss_and_ea_group_as_all_selected
# rake service_group:add_service_group_setting
# rake service_group:remove_invalid_tags
# rake service_group:move_allocation_tag_to_allocation_ratio

namespace :service_group do
  desc 'One time task to set is_group_empty flag true for groups having adapter_ids field as []'

  task update_empty_adapter_group_flag: :environment do
    CSLogger.info 'Started updating empty group flag'
    Account.all.each do |account|
      adapter_groups = account.service_groups.adapter_groups.where('json_array_length(array_to_json(adapter_ids)) = 0')
      next unless adapter_groups

      adapter_groups.update_all(is_group_empty: true)
      CSLogger.info "#{adapter_groups.size} : empty adapter_group(s) updated for account : #{account.organisation.subdomain}"
    end
  end

  # One time task after deployment
  task clean_deprecated_groups: :environment do
    desc 'Task to remove resource_group and tag_group from ServiceGroup'
    types = ['Groups::Resource', 'Groups::Tag']
    CSLogger.info '============ Removing Deprecated groups from cloudstreet ============'
    ServiceGroup.where(type: types).in_batches.delete_all
  end

  # One time task after deployment
  task migrate_old_to_new: :environment do
    desc 'Migrate adapter_group to new group version'
    udpate_columns = { conflict_target: [:id], columns: %i[normal_adapter_ids] }
    Account.all.each do |account|
      CSLogger.info " ========== Migrating groups for organisation : #{account.organisation.subdomain} ========="
      groups = account.service_groups.where(type: 'Groups::Adapter')
      groups.each do |group|
        # adapter_ids contains adapter info as {'id' =>'', 'name' => '', 'state' => ''}
        adapter_ids = group.adapter_ids.pluck('id').compact
        group.normal_adapter_ids = adapter_ids     
      end
      next if groups.empty?

      ServiceGroup.import groups.to_a, on_duplicate_key_update: { conflict_target: [:id], columns: [:normal_adapter_ids] }
    end
  end

  # One time task after deployment
  task update_gcp_service_groups: :environment do
    normal_adapters_non_empty_query = 'json_array_length(array_to_json(normal_adapter_ids)) != 0'
    ServiceGroup.where(provider_type: 'GCP').where(normal_adapters_non_empty_query).each do |group|
      tenant = group.tenant
      tenant_adapter_ids = group.send(:normal_adapters_through_billing) # fetching all normal ids from the billing adapter through group
      all_selected = tenant_adapter_ids.all? { |id| group.normal_adapter_ids.include?(id) }
      group.update_column(:normal_adapter_ids, []) if all_selected
    end
  end

  # Rake task to update old adapter group
  # make normal_adapter_ids = [] if the normal_adapter_ids list contains
  # all the linked normal adapter of the group's billing adapter
  task update_aws_group_as_all_selected: :environment do
    normal_adapters_non_empty_query = 'json_array_length(array_to_json(normal_adapter_ids)) != 0'
    ServiceGroup.where(provider_type: 'AWS').where(normal_adapters_non_empty_query).each do |group|
      billing_adapters_link_adapter_ids = group.send(:normal_adapters_through_billing)
      all_selected = billing_adapters_link_adapter_ids.all? { |id| group.normal_adapter_ids.include?(id) }
      if all_selected
        CSLogger.info "========== Updating Group-Name-> #{group.name}, ID-> #{group.id}, Subdomain-> #{group.account.organisation.subdomain} ========"
        group.update(normal_adapter_ids: [])
      end
    end
  end

  # Rake task to check all the existing 'Selected All' group
  # Apply validation and update groups.
  # 1 : Make Group partial if not eligible for select all
  # 2 : Make Group empty if no normal account/subscription/project present.
  task apply_validation_to_existing_groups: :environment do
    desc 'One time rake task to apply validation to existing `SELECTED ALL` based group'
    Account.active.each do |account|
      groups_to_update = []
      CSLogger.info "STARTED : ====== Applying validation to existing groups of Organisation - #{account.organisation.subdomain} ======"
      groups = account.service_groups.all_selected_groups
      groups.each do |group|
        begin
          validator_obj = Groups::Validator.new(group.tenant, group.attributes)
          next if validator_obj.allow_select_all?

          normal_adapter_ids = validator_obj.send(:applicable_normal_adapter_ids)
          if normal_adapter_ids.nil?
            CSLogger.info "#{group.type} ---- Group #{group} : Making group empty as no normal adapters found ----"
            group.is_group_empty = true
          else
            CSLogger.info "#{group.type} ---- Group #{group} : Making group Partial ----"
            group.normal_adapter_ids = normal_adapter_ids
          end
          groups_to_update << group
        rescue Exception => e
          CSLogger.error "EXCEPTION : ---- #{e.message} ---- "
          CSLogger.error "BACKTRACE ---- #{e.backtrace} ---- "
          CSLogger.info "SKIPPING : ---- Due to above error we are skipping this group : ID : #{group.id} | Name: #{group.name} ----"
          next
        end
      end
      ServiceGroup.import groups_to_update, on_duplicate_key_update: { conflict_target: [:id], columns: %i[normal_adapter_ids is_group_empty] }
      CSLogger.info "COMPLETED : ====== Validation applied for all existing groups of Organisation - #{account.organisation.subdomain} ======"
    end
  end

  # One time rake task to update existing Azure SS and EA groups.
  # update normal_adapter_ids = [] if the normal_adapter_ids list contains
  # all the linked normal adapter of the group's billing adapter
  # part of ticket -> CSMP-20728
  task mark_azure_ss_and_ea_group_as_all_selected: :environment do
    normal_adapters_non_empty_query = 'json_array_length(array_to_json(normal_adapter_ids)) != 0'
    updated_organisation_groups = {}
    Account.active.each do |account|
      azure_ss_and_ea_billings = account.adapters.azure_adapter.billing_adapters.select { |a| a.try(:is_ss_billing?) || a.try(:ea_adapter?) }
      CSLogger.info " ==== INFO : Started for organisation - #{account.organisation.subdomain} | No of EA + SS billing subscription -> #{azure_ss_and_ea_billings.count}"
      tenant = account.organisation.tenants.default
      azure_ss_and_ea_billings.each do |adapter|
        begin
          account.service_groups.where(billing_adapter_id: adapter.id).where(normal_adapters_non_empty_query).each do |group|
            params = { billing_adapter_id: adapter.id, type: 'Azure', require_all_adapters: true }
            billing_adapters_link_adapter_ids = AdapterSearcher.fetch_normal_adapters(account, tenant, params)[:adapters].pluck(:id)
            next if billing_adapters_link_adapter_ids.empty?

            CSLogger.info " ==== INFO : Group Name -> #{group.name} | Group ID #{group.id} | Normal subscription count in group -> #{group.normal_adapter_ids.count} | Total Linked normal subscriptions count -> #{billing_adapters_link_adapter_ids.count}" 
            all_selected = billing_adapters_link_adapter_ids.all? { |id| group.normal_adapter_ids.include?(id) }
            if all_selected
              CSLogger.info "========== UPDATING : Group-Name-> #{group.name}, ID-> #{group.id}, organisation-> #{account.organisation.subdomain} ========"
              group.update(normal_adapter_ids: [])
              (updated_organisation_groups[account.organisation.subdomain] ||= []) << group.id 
            end
          end
        rescue Exception => e
          CSLogger.error "@@@@@@@ ERROR : while updating azure SS/EA group as `select-all` please check log @@@@@@"
          CSLogger.error " ========== #{e.message} \n #{e.backtrace.first}"
        end
      end
    end
    CSLogger.info "===== COMPLETED : Successfuly updated Azure SS/EA groups for all accounts ====="
    CSLogger.info "RAKE SUMMARY : Groups updated organisation wise --> #{updated_organisation_groups}"
  end

  # store default aws_account_tag_key
  # in aws account_tag based groups
  task assign_aws_account_tags: :environment do
    default_tag_key = { aws_account_tag_key:  AWSAccountTag::DEFAULT_TAG_KEY }
    Account.active.each do |account|
      account.service_groups.where(group_based_on_account_tag: true).find_each do |group|
        next if group.aws_account_tag_key.present?

        group.update(data: group.data.merge(default_tag_key))
      end
    end
  end

  task add_service_group_setting: :environment do
    adapter_info = []
    Adapter.available.billing_adapters.each do |adapter|
      # skipping if adapter is gcp,vmware or if adapter has service group setting
      next if adapter.is_gcp? || adapter.is_vm_ware?
      next if adapter.service_group_setting.try(:whitelisted_tag_keys).present?
      tag_keys = adapter.service_groups.pluck(:tags).flatten.pluck("tag_key").uniq
      CurrentAccount.client_db = adapter.account
      tag_key_display_names = TagName.where(adapter_id: adapter.id).pluck(:display_name)
      # selecting the tags which are present in athena only.
      tag_keys.select! { |tag_key| tag_key_display_names.include?(tag_key) }
      next unless tag_keys.length == 1

      adapter_info << { adapter_id: adapter.id, org_identifier: adapter.account.organisation_identifier, tag_keys: tag_keys}
      service_group_setting = ServiceGroupSetting.find_or_create_by(adapter_id: adapter.id)
      service_group_setting.update_attribute(:whitelisted_tag_keys, [tag_keys.first.strip])
    end
    CSLogger.info "Created Service Group Setting for following adapters: #{adapter_info}"
  end

  task remove_invalid_tags: :environment do
    adapter_info = []
    Adapter.available.billing_adapters.each do |adapter|
      # skipping if adapter is gcp,vmware or if adapter has service group setting
      next if adapter.is_gcp? || adapter.is_vm_ware?

      CurrentAccount.client_db = adapter.account
      tag_key_display_names = TagName.where(adapter_id: adapter.id).pluck(:display_name)
      adapter.service_groups.service_tag_based_groups.group_by(&:account_id).each do |account_id, service_groups|
        service_groups.each do |service_group|
          service_group.tags.select! { |tag| tag_key_display_names.include?(tag['tag_key']) }
          service_group.save!
        end
        account = Account.find_by(id: account_id)
        AthenaTableSchemaUpdateWorker.perform_action(account.organisation_identifier, adapter.type.gsub("Adapters::", ''))
      end
    end
    CSLogger.info "Created Service Group Setting for following adapters: #{adapter_info}"
  end

  task move_allocation_tag_to_allocation_ratio: :environment do
    desc 'Move group tag Allocation data into Allocation Ratio column'
    feature = Flipper.feature($flipper_feature['aws_support_for_cardinality_based_query_feature'].to_sym)
    Account.all.each do |account|
      next unless feature.enabled?(account.organisation)
      groups = account.service_groups.where(provider_type: 'AWS')
      groups.each do |group|
        allocation_ratio = group.custom_data['Allocation']
        group.allocation_ratio = (allocation_ratio || '1').to_f
        group.save!
        puts "Allocation Ratio is updated for ##{group.name}"
      end
    end
  end
end

