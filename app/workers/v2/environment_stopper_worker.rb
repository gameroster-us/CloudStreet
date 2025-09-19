class V2::EnvironmentStopperWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(environment_id, user_id)
    environment     = Environment.find(environment_id)
    user            = User.find(user_id)
    V2::Environments::EnvironmentStopper.execute(environment, user)
    CSLogger.info "Successfully ran EnvironmentStopper.stop(#{environment.id})"
    environment.reload
  end
end