module MarketplaceAdapter

  def self.get_default_adapter
    if OrganisationDetail.table_exists?
      organisation_detail = OrganisationDetail.first
      if organisation_detail
        s3_config = organisation_detail.s3_config
        if s3_config.present?
          adapter = Adapter.where(id: s3_config["adapter_id"]).first
          adapter.bucket_id = s3_config["bucket_id"]
          adapter.bucket_region_id = s3_config["bucket_region_id"]
          if adapter
            adapter.get_sts_connection_credentials if adapter.data["role_arn"].present?
            adapter
          else
            CSLogger.info("S3 Bucket Adapter not set")
            default_adapter
          end
        else
          CSLogger.info("S3 Config not set")
          default_adapter
        end
      else
        CSLogger.info("OrganisationDetail not set")
        default_adapter
      end
    else
      CSLogger.info("OrganisationDetail table does not exist")
      default_adapter
    end
  end

  def self.default_adapter
    adapter = Adapters::AWS.directoried.first
    adapter.access_key_id = CommonConstants::RDS_DUMP_ACCESS[:access_key_id]
    adapter.secret_access_key = CommonConstants::RDS_DUMP_ACCESS[:secret_access_key]
    adapter.connection(nil, true)
    adapter
  end
end
