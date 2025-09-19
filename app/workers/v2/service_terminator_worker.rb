class V2::ServiceTerminatorWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(environment_id, service_type, CS_service_id)
    begin
      redis_hash_name = "environment_terminator_#{environment_id}"
      adapter, subscription = nil, nil
      ::REDIS.with do |conn|
        adapter = Adapter.new JSON.parse(conn.hget(redis_hash_name, "adapter"))
        subscription = Subscriptions::Azure.new JSON.parse(conn.hget(redis_hash_name, "subscription"))
      end
      CSLogger.info "adapter-- #{adapter.inspect}, subscription- #{subscription.inspect}"
      service_type = ActionController::Base.helpers.sanitize(service_type)
      
      detail_service = service_type.constantize.find_by_CS_service_id(CS_service_id)
      detail_service.provider_client = service_type.constantize.create_provider_client(adapter, subscription.provider_subscription_id) if adapter.present? && subscription.present?
      detail_service.terminate
    rescue Exception => e
      CS_service_obj = CSService.find_by(service_type: service_type, id: CS_service_id)
      if CS_service_obj.present?
        CS_service_obj.state = "error"
        CS_service_obj.error_message = e.message
        CS_service_obj.save!
      end
      raise e
    end
  end
end