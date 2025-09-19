# frozen_string_literal: true

module VmWare
  class InventoryDataWorker

    include Sidekiq::Worker
    sidekiq_options queue: :metric, retry: false, backtrace: true

    def perform(vw_vdc_file_id, remaining_file_ids = [], is_reprocess = false)
      vw_vdc_file = VwVdcFile.find_by(id: vw_vdc_file_id)

      return unless vw_vdc_file

      begin
        CloudStreet.log "===== Worker initiated for VwVdcFile id = #{vw_vdc_file_id} and Adapter ID = #{vw_vdc_file.adapter_id} ===== remaining file count #{remaining_file_ids.count}"
        if is_reprocess
          VmWare::InventoryDataService.new(vw_vdc_file).process(false, is_reprocess)
        else
          VmWare::InventoryDataService.new(vw_vdc_file).process
          FocusConversion::SnsService::VmWare.publish_to_sns(vw_vdc_file)
        end
      rescue StandardError => e
        vw_vdc_file.update_file_process_timestamp('failed') if e.is_a?(NoMethodError) && e.message.include?('read')
        CloudStreet.log "Failed to process file ID #{vw_vdc_file_id}: #{e.message}"
        Honeybadger.notify(e, error_class: 'VmWare::InventoryDataWorker', error_message: e.message, parameters: { vw_vdc_file_id: vw_vdc_file_id }) if ENV['HONEYBADGER_API_KEY'] && !(e.is_a?(NoMethodError) && e.message.include?('read'))
      end

      if remaining_file_ids.any?
        next_file_id = remaining_file_ids.shift
        self.class.perform_async(next_file_id, remaining_file_ids, is_reprocess)
      else
        unless ENV['STOP_UNPROCESSED_VDC_FILES'].to_s == 'true'
          unprocessed_file_id = find_unprocessed_file(vw_vdc_file)
          CloudStreet.log "===== Unprocessed VwVdcFile id = #{unprocessed_file_id} and Adapter ID = #{vw_vdc_file.adapter_id} ====="
          self.class.perform_async(unprocessed_file_id, [], true) if unprocessed_file_id.present?
        end
      end
    end

    private

    def find_unprocessed_file(vw_vdc_file)
      reprocess_date_count = CommonConstants::VMWARE_DATA_REPROCESS_DAY || 10
      time_range_start = Date.today - reprocess_date_count.day
      time_range_end = Time.now - 2.hours
      if vw_vdc_file.created_at.to_date >= time_range_start
        VwVdcFile.where(adapter_id: vw_vdc_file.adapter_id).where(created_at: time_range_start.beginning_of_day..time_range_end).where("additional_details ->> 'process_end_time' IS NULL AND additional_details ->> 'source_date' IS NULL").order(:created_at).first&.id # Get file ID
      end
    end

  end
end
