module Azure
  class VpcCreateWorker
    include Sidekiq::Worker
    sidekiq_options queue: :api, :retry => false, backtrace: true

    def perform(vpc_id, options)
      begin
        CSLogger.info "IN vpc VpcCreaterWorker-----#{options.inspect}"
        vpc = CSService::VNET.constantize.find(vpc_id)
        vpc.update_remote_and_CS(options, vpc.subscription_id)
        CSLogger.info "Successfully ran VpcCreaterWorker"
      rescue Exception => exception
        CSLogger.error "CLASS => #{exception.class}, MESSAGE CLASS => #{exception.message.class}"
        message = exception.message.to_json
        CSLogger.info "MESSAGE JSON  => #{message}"
        message = ActiveSupport::JSON.decode(message)
        vpc.CS_service.update(state: 'error', error_message: JSON.parse(message)["message"])
      end
    end
  end
end
