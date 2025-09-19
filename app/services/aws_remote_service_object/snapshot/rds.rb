module AWSRemoteServiceObject::Snapshot
  class Rds < Struct.new(:provider_data, :provider_id, :allocated_storage, :availability_zone, :instance_id, :engine, :PercentProgress, :IAMDatabaseAuthenticationEnabled, :OptionGroupName, :engine_version, :master_username, :type, :instance_created_at, :DBSnapshotArn, :ProcessorFeatures, :encrypted, :port, :created_at, :license_model, :storage_type, :state, :first_snapshot, :tags, :key_id)
    def get_attributes_for_service_table
      {
        provider_data: provider_data,
        type: "Snapshots::AWS",
        publicly_accessible: false,
        data: data_attributes,
        category: "rds",
        description: provider_data["id"] + ":" + instance_id,
        name: provider_data["id"],
        state: "created",
        provider_id: provider_data["id"],
        provider_created_at: provider_data["created_at"]
      }
    end

    def data_attributes
      {
        encrypted: encrypted,
        snapshot_type: type,
        kms_key_id: (key_id && key_id.split("/").last),
        tags: tags
      }
    end

    def self.parse_from_json(data)
      new(
        data,
        data["id"],
        data["allocated_storage"],
        data["availability_zone"],
        data["instance_id"],
        data["engine"],
        data["PercentProgress"],
        data["IAMDatabaseAuthenticationEnabled"],
        data["OptionGroupName"],
        data["engine_version"],
        data["master_username"],
        data["type"],
        data["instance_created_at"],
        data["DBSnapshotArn"],
        data["ProcessorFeatures"],
        data["encrypted"],
        data["port"],
        data["created_at"],
        data["license_model"],
        data["storage_type"],
        data["state"],
        data["first_snapshot"],
        data["tags"],
        data["key_id"]
      )
    end
  end
end
