class ProviderWrappers::AWS::Computes::Snapshot < ProviderWrappers::AWS

    def modify_backup_attribute(backup_id, options)
      ProviderWrappers::AWS.retry_on_timeout{
        @agent.modify_snapshot_attribute(backup_id, { "#{options[:action]}.UserId"=> [options[:destination_account_id]]})
      }
    end

    def add_tags_to_resource(resource_id, tags)
      @agent.create_tags(resource_id, tags)
    end

    def copy_to_region(backup_id, options)
      ProviderWrappers::AWS.retry_on_timeout{
        response =  @agent.copy_snapshot(backup_id, options[:source_region_code], options[:target_description])
        yield(response.data[:body]["snapshotId"]) if block_given?
        response.data[:body]["snapshotId"]
      }
    end

    def delete_temp_backup(backup_id)
      backup = fetch_remote_service(backup_id)
      backup.destroy if backup
    end

    def fetch_remote_service(provider_id)
      ProviderWrappers::AWS.retry_on_timeout{
        agent.snapshots.get(provider_id)
      }
    end

  class << self

    def all(agent, filters = {})
      retry_on_timeout {
        return agent.snapshots.all
      }
    end
  end

end
