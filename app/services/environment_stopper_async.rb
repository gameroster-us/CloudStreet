class EnvironmentStopperAsync < CloudStreetServiceAsync
  def self.execute(environment, user, &block)
    environment = fetch Environment, environment
    user        = fetch User, user

    EnvironmentStopperWorker.perform_async(environment.id, user.id)
    status EnvironmentStatus, :success, environment, &block
  end
end
