class Athena::S3UploaderService
  class << self
    def upload_file(vcenter_id, vw_vdc_file, csv_file_name)
      adapter = Adapters::AWS.get_default_adapter
      s3_file = build_s3_file_name(vcenter_id, vw_vdc_file.id, vw_vdc_file.created_at.strftime('%Y-%m'))
      s3_client = AWSSdkWrappers::S3::Client.new(adapter, APP_REGION).client
      s3 = Aws::S3::Resource.new({ name: RAW_METRIC_BUCKET, client: s3_client })
      obj = s3.bucket(RAW_METRIC_BUCKET).object(s3_file)

      CSLogger.info '=======================File upload started========================================'
      obj.upload_file("#{Rails.root}/#{csv_file_name}")
      CSLogger.info '=======================File upload completed======================================'
      []
    rescue StandardError => e
      Honeybadger.notify(e) if ENV['HONEYBADGER_API_KEY']
      CSLogger.error e.message
      CSLogger.error e.backtrace
      []
    end

    def build_s3_file_name(vcenter_id, vw_vdc_file_id, month)
      year = "year=#{month.split('-').first}"
      month = "month=#{month.split('-').last}"

      org_identifier = get_org_identifier(vcenter_id)
      s3_path_prefix = "#{org_identifier}/#{vcenter_id}/#{year}/#{month}/#{vw_vdc_file_id}.csv"
    rescue Exception => e
      Honeybadger.notify(e) if ENV['HONEYBADGER_API_KEY']
      CSLogger.error e.message
      CSLogger.error e.backtrace
    end

    def get_org_identifier(vcenter_id)
      vcenter = VwVcenter.find_by(id: vcenter_id)
      vcenter.organisation_identifier
    end
  end
end
