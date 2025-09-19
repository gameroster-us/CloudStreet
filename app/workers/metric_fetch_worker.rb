class MetricFetchWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :metric, :retry => false, :backtrace => true

  def perform(synced=false, service_ids=nil)
    unless synced
      MetricStorage.store_api_data
    else  	 
      metric_services = Service.where(id: service_ids)
      MetricStorage.fetch_and_store_data(metric_services, true) unless metric_services.blank?
    end
  rescue => exception
    CSLogger.error "#{exception.backtrace}" 
    raise exception	
  end
end
