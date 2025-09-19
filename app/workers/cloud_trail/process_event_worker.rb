module CloudTrail
  class ProcessEventWorker
    include Sidekiq::Worker
    sidekiq_options queue: :cloud_trail, retry: false, backtrace: true

    def perform(adapter_id)
      adapter = Adapter.find(adapter_id)
      CloudTrailEvent.update_status(adapter)
      CloudTrail::Processor.process_bulk_events(adapter, batch.bid)
      adapter.aws_cloud_trail.update(last_process_time: DateTime.now) unless adapter.aws_cloud_trail.blank?
    rescue StandardError => e
      CTLog.error e.message
      CTLog.error e.backtrace
    end

  end
end
