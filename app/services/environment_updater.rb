class EnvironmentUpdater < CloudStreetService
  def self.update(environment, params, user_id, &block)
    environment = fetch Environment, environment

    CSLogger.info "UPDATING ENVIRONMENT"
    CSLogger.info params.inspect

    # if params[:adapter_id]
    #   CSLogger.info "Updating default adapter id for environment"
    #   environment.default_adapter_id = params[:adapter_id]

    #   environment.updated_by = user.id
    #   environment.save!
    #   params.delete(:adapter_id)
    # end
    
    environment.assign_attributes params
    environment.updated_by = user_id
    unless environment.save
      errors = environment.errors.messages
      status Status, :validation_error, errors, &block
      return environment
    end
    status Status, :success, environment, &block
    return environment
  end

  def self.update_environnment_access(account, environment_access_params, &block)
    environment_access_params[:user_role_ids] = [] if environment_access_params[:user_role_ids]==nil
    account = fetch Account, account
    organisation = account.organisation
    if environment_access_params[:user_role_ids]!=[] && !organisation.has_roles?(environment_access_params[:user_role_ids])
      status Status, :validation_error, "roles_not_found" , &block
      return nil
    end  

    env = fetch Environment, environment_access_params[:id]
    if !env
      status Status, :not_found, nil, &block
      return nil
    end

    updated = env.assign_accessible_roles(account, environment_access_params[:user_role_ids])

    if updated
      status Status, :success, env, &block
      return env
    else
      return nil  
    end
  end

  def self.reapply_tags(environment, &block)
    environment = fetch Environment, environment

    if environment.reapply_tags_to_services
      status Status, :success, environment, &block
      return environment
    else
      status Status, :error, environment, &block
      return environment
    end
  end  

  def self.reload(environment, user, &block)
    begin
      if Environment::RELOADABLE_STATES.include?(environment.state.to_sym)
        adapter = environment.default_adapter
        region_code = environment.region.code

        EnvironmentReloader.new(environment, user, adapter, region_code).reload # it has main batch for reload

        # revision_data = environment.prepare_revision_data(event: 'reloaded')
        # Events::Environment::Create.create(account: environment.account, environment: environment, user: user, revision_data: revision_data)
        
        status Status, :success, environment, &block
      else
        status Status, :error, environment, &block
      end
    rescue Exception => e
      status Status, :error, environment, &block
    end
  end
end
