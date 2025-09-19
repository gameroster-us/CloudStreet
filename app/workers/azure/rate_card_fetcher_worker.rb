class Azure::RateCardFetcherWorker
  include Sidekiq::Worker
  sidekiq_options queue: :azure_sync, :retry => 10, backtrace: true

  def perform(adapter_id)
    adapter = Adapters::Azure.find_by(id: adapter_id)
    return if adapter.blank? || adapter.subscription.blank?
    adapter.subscription.reload_rate_cards
  end
end
