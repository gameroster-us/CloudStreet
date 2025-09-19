class RegionListWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform()
  	CSLogger.info 'fetching all regions'
  	Region.fetchAll
  rescue => exception
    CSLogger.error "#{exception.backtrace}" 
    raise exception	
  end
end
