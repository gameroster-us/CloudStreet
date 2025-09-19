# rake sync_adapters:auto_sync

namespace :sync_adapters do
  desc 'This task is to run auto sync'
  task auto_sync: :environment do
    CSLogger.info '******* Auto-sync started in backgorund ********'
    region_codes = Region.aws.pluck(:code).uniq
    adapters = Adapters::AWS.normal_adapters.where(state: 'active', type: 'Adapters::AWS', sync_running: false)
    adapters = adapters.select { |adapter| adapter.cloud_trail_enable == 'false' && adapter.check_if_not_synced_for_7_days? }
    adapters = adapters.collect do |adapter|
      if (adapter.aws_cloud_trail.present?)
        (adapter.aws_cloud_trail.last_trail_time < Time.now - 7.days) && !adapter.aws_cloud_trail.running ? adapter : nil
      else
        adapter
      end
    end.compact
    
    batch_count = (adapters.count.to_f / 24).ceil()
    if !batch_count.zero? 
      adapters.to_a.each_slice(batch_count).with_index do |grouped_adapters, index|
        grouped_adapters.each do |adapter|
          AutoSyncWorker.perform_at(DateTime.now + index.hours , adapter.id)
        end
      end
    end

  end
end

