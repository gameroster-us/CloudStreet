class MachineImagesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api, :retry => false, backtrace: true


  def perform(adapter_id, region_id, filters)
    adapter = Adapter.find(adapter_id)
    region = Region.find(region_id)
    CSLogger.info "Fetching AMIs for #{region.region_name}"
    MachineImageFetcher.fetch_amis(adapter, region, filters)
    CSLogger.info "Finished Fetching AMIs for #{region.region_name}"
  rescue => exception
    CSLogger.error "An Error Occured #{exception.message}"
    CSLogger.error "Error Trace #{exception.backtrace}"
    raise exception
  end
end