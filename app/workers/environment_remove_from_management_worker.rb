class EnvironmentRemoveFromManagementWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api, :retry => false, backtrace: true

  def perform(environment_id, user_id)
    environment     = Environment.find(environment_id)
    user            = User.find(user_id)

    if environment.remove_from_management
      Events::Environment::Delete.create(account: environment.account, environment: environment, user: user)
      environment.account.create_info_alert(:env_removed_from_management, {name: environment.name})
      ImageService.delete_local_image(environment_id,'environments')
    end
    CSLogger.info "Successfully ran environment.remove_from_management"
  end
end
