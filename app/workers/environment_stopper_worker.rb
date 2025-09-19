class EnvironmentStopperWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(environment_id, user_id)
    environment     = Environment.find(environment_id)
    user            = User.find(user_id)
    #EnvironmentStopper.stop_services(environment_id, user_id)

    EnvironmentStopper.execute(environment, user)

    CSLogger.info "Successfully ran EnvironmentStoppable.stop(#{environment.id})"

    # Events::Environment::Stop.create(account: current_account, environment: environment, user: user)
  rescue => exception
    CSLogger.error "#{exception.backtrace}" 
    #raise exception
  end
end
