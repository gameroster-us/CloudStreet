module VmWare
  class MetricsDataWorker
    include Sidekiq::Worker
    sidekiq_options queue: :metric, retry: false, backtrace: true

    def perform(vcenter_id, vw_vdc_file_id)
      vw_vdc_file = VwVdcFile.find_by(id: vw_vdc_file_id)
      vcenter = VwVcenter.find_by(id: vcenter_id)
      return if vw_vdc_file.blank? || vcenter.blank?

      csv_file = VmWare::MetricsDataService.new(vcenter, zip(vw_vdc_file)).process
      clean_file!("#{vw_vdc_file.id}_metric.zip")
      adapter = vcenter.adapter
      begin
        CSLogger.info "started uploading  to #{RAW_METRIC_BUCKET} for adapter - #{adapter.name}"
        Athena::S3UploaderService.upload_file(vcenter_id, vw_vdc_file, csv_file)
        CSLogger.info "upload complete #{csv_file}"
        clean_file!(csv_file)
      rescue Exception => e
        if ENV['HONEYBADGER_API_KEY']
          Honeybadger.notify(e,
                           error_class: 'VmWare::MetricsDataWorker',
                           error_message: e.message,
                           parameters: { vcenter_id: vcenter_id, vw_vdc_file_id: vw_vdc_file.id })
        end
      ensure
        clean_file!("#{vw_vdc_file.id}_metric.zip")
        clean_file!(csv_file)
      end
    end

    private

    def zip(vw_vdc_file)
      File.open("#{vw_vdc_file.id}_metric.zip", 'wb') { |f| f.write(vw_vdc_file.zip.read) }
      @zip = Zip::File.open("#{vw_vdc_file.id}_metric.zip")
    end

    def clean_file!(path)
      File.delete(path) if File.exist?(path)
    end
  end
end
