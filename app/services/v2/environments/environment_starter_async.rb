class V2::Environments::EnvironmentStarterAsync < CloudStreetServiceAsync
  def self.execute(environment, user, prev_env_state, &block)
    CSLogger.info "In V2::Environments::EnvironmentStarterAsync.execute"
    # Have to pull environment out again as the block code will expect it
    environment = fetch Environment, environment
    user        = fetch User, user

    V2EnvironmentStarterWorker.perform_async(environment.id, user.id, prev_env_state)
    status EnvironmentStatus, :success, environment, &block
  end
end