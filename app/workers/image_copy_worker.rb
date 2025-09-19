class ImageCopyWorker
  include Sidekiq::Worker

  sidekiq_options queue: :api, retry: false, backtrace: true

  def perform(options)
  	ImageService.copy_from_template_to_environment_bucket(options["source"], options["destination"])
  rescue Exception => e
  	CSLogger.error e.message
  	CSLogger.error e.backtrace
  end

end