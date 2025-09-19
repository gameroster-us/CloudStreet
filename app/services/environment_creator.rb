class EnvironmentCreator < CloudStreetService
  def self.create(params, user, current_account, &block)
    account = fetch Account, params[:account_id]
    user_role_ids = user.user_role_ids.pluck :id
    params.merge!(user_role_ids: user_role_ids)
    CSLogger.info "params ---- #{params.inspect}"
    environment = account.environments.build(params)

    CSLogger.error environment.errors.inspect
    environment.created_by = user.id
    environment.updated_by = user.id
    environment.save

    current_account = Account.find(current_account)
    user = User.find(user)
    Events::Environment::Create.create(account: current_account, environment: environment, user: user)

    status Status, :success, environment, &block
    return environment
  end
end
