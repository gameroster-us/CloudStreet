class VpcCostUpdaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(adapter_id)
    # Fixed N+1 query
    result = Vpc.includes(:services).where(adapter_id: adapter_id, state: "available").inject([]) do |memo, vpc|
      vpc.unallocated_services_cost = vpc.services.synced_services.chargeable_services.sum(:cost_by_hour)
      memo << vpc
    end
    Vpc.import(result, validate: false, on_duplicate_key_update: {conflict_target: [:id], columns: [:provider_data]})
  end
end
