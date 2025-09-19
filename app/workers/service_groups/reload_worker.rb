module ServiceGroups
  class ReloadWorker
    include Sidekiq::Worker
    sidekiq_options queue: :athena_group_sync, backtrace: true

    def perform(group_ids)
      group_ids = Array[* group_ids]
      group_ids.select! { |group_id| UUID.validate(group_id) }
      ServiceGroup.where(id: group_ids).each do |group|
        # currently only account tag based groups are getting updated here
        next unless group.is_account_tag_based_group?

        begin
          ActiveRecord::Base.transaction do
            old_adapter_ids_from_group = group.normal_adapter_ids
            old_group_name = group.name
            # => Update normal adapter information for only partial group
            # =>  For common adapter checking we need the billing adapter level linked normal adapter Ids
            # of the account_tag present in current group
            # =>  Update the normal_adapter_ids column of the current group and keep
            # only common adapters, and mark the group empty if there is no normal_adapter_ids remain
            if group.is_partial_group?
              current_normal_adapter_ids = group.send(:normal_adapters_through_billing)
              group.normal_adapter_ids = (old_adapter_ids_from_group & current_normal_adapter_ids)
              group.is_group_empty = true if group.normal_adapter_ids.empty?
              group.save
            end
            args = {
              account: group.account,
              tenant: group.tenant,
              user: group.account.organisation.owner,
              service_group: group,
              old_adapter_ids: old_adapter_ids_from_group,
              account_group_flag: true,
              old_group_name: old_group_name
            }
            CSLogger.info("==== Group updation done Group : #{group.name}-- Now started updating its dependencies ====")
            ::Groups::Updater.perform_post_updation_tasks(args)
          end
        rescue StandardError => e
          CSLogger.error("***** Error while reloading Group : #{group.name} | ID: #{group.id} | Error : #{e.message} *****")
        end
      end
    end
  end
end