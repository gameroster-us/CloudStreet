# Gcp Resource Pricing Worker
class GCP::ResourcePricingWorker
  include Sidekiq::Worker
  sidekiq_options queue: :gcp_sync

  def perform
    gcp_adapter = Adapters::GCP.directoried
    return unless gcp_adapter.any?

    # Calling Service to fetch the price list and dump into the db
    GCP::Resource::Pricing::ComputeEngine.fetch_and_dump_price
  end
end
