# frozen_string_literal: true

class Adapters::VmWare < Adapter
  has_many :vw_vcenters, dependent: :destroy, foreign_key: :adapter_id
  has_many :vw_vdc_files, foreign_key: :adapter_id
  has_many :vw_events, through: :vw_vcenters

  store_accessor :data, :report_status

  self.authorizer_name = "VmWareBudgetAuthorizer"

  def organisation_identifier
    @organisation_identifier ||= account.organisation.try(:organisation_identifier)
  end

  def athena_cost_report_table
    <<~TABLE_NAME.squish.gsub(' ', '')
      #{ATHENA_DATABASE}.
      #{organisation_identifier}_
      ad_#{id.split('-').last}_
      vm_ware
    TABLE_NAME
  end


  def delete_all_data
    if self.vw_vdc_files.present?
      self.remove_vw_vdc_file_directory
      self.vw_vdc_files.destroy_all
      CSLogger.info "vw vdc files deleted"
    end
  end

  def remove_vw_vdc_file_directory
    begin
      aws_adapter = Adapters::AWS.get_default_adapter
      s3_client = AWSSdkWrappers::S3::Client.new(aws_adapter, ENV['S3_BUCKET_REGION']).client
      s3 = Aws::S3::Resource.new(client: s3_client)
      directory_path = vw_vdc_files.last.zip.store_dir
      objects = s3.bucket(ENV['S3_BUCKET_NAME']).objects({prefix: directory_path})
      objects.batch_delete! if objects.any?
      CSLogger.info "Deleted vw vdc file directory - #{directory_path}"
    rescue StandardError => error
      CSLogger.error error.message
    end
  end

  def fetch_vw_vcenter_ids
    vw_vcenters.ids rescue []
  end

  def fetch_vw_vcenter_provider_ids
    vw_vcenters.pluck(:provider_id) rescue []
  end

  class << self
    def fetch_vw_vcenter_ids_through_billing(adapter_id)
      Adapters::VmWare.find(adapter_id).vw_vcenters.ids rescue []
    end
  end
end
