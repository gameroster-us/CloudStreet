class VpcCreaterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(vpcid)
    CSLogger.info "IN vpc VpcCreaterWorker-----#{vpcid}"
    vpc = Vpc.find(vpcid)
    vpc.create
    CSLogger.info "Successfully ran VpcCreaterWorker"
  end
end