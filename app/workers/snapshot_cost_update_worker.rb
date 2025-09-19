class SnapshotCostUpdateWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true
  def perform
    Snapshot.find_in_batches.each do |snapshots|
      snapshots.each do |snapshot|
        snapshot.cost_by_hour = snapshot.calculate_hourly_cost
        snapshot.save
        CSLogger.info "#{snapshot.name} updated!"
      end
    end
  end
end