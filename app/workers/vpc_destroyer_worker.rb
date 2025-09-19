class VpcDestroyerWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :api, :retry => false, backtrace: true

  def perform(vpcid)
    vpc = Vpc.find(vpcid)
    vpc.archived
    vpc.internet_gateway.remove_from_provider if vpc.internet_gateway
  rescue => exception
    CSLogger.error "--------------1--------#{exception.message}" 
    CSLogger.error "---------------2-------#{exception.backtrace}" 
    raise exception
  end
end