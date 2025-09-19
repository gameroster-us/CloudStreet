class ApplicationService < CloudStreetService
  def self.find(application, &block)
    status Status, :success, application, &block
    return application
  end
    
  def self.search(user, organisation, page_params, filter_params, has_access_right, &block)
    account = organisation.account
    applications = Application.by_account_with_enviornments_count(account.id).order(updated_at: :desc)
    applications = applications.where("applications.name ILIKE ?", "%#{filter_params[:name]}%") if filter_params[:name].present?
    applications = applications.by_access_roles(user.user_roles.map(&:id)) unless has_access_right

    applications = applications.set_restriction(user.user_roles.map(&:id))
    total_records = applications.except(:select).length
    if !page_params[:page_size].blank? && !page_params[:page_number].blank?
      paginated_applications = applications.paginate({:page => page_params[:page_number].to_i, :per_page => page_params[:page_size].to_i})
    end
    status Status, :success, [paginated_applications, total_records], &block
    return paginated_applications
  end

  def self.create(organisation, user, application_attributes, environments_params=nil, &block)
    account = organisation.account
    application_attributes[:access_roles] = [] if application_attributes[:access_roles].nil?
    application = Application.new application_attributes
    application.account_id = account.id
    application.creator=user
    application.updator=user
    if application.save
        add_environments(application,environments_params) unless environments_params.nil?
        Events::Application::Create.create(account: account, application: application, user: user)
        application.check_application_cost
        status Status, :success, application, &block
    else
        status Status, :validation_error, application.errors.messages, &block
    end
    return application
  end

  def self.update(organisation, user, application,application_attributes, environments_params=nil, &block)
    account = organisation.account
    application_attributes[:access_roles] = [] if application_attributes[:access_roles].nil?
    application_attributes[:notify_to] = [] if application_attributes[:notify_to].blank? || application_attributes[:notify] == false
    application.attributes = application_attributes
    application.creator=user unless application.creator.present? 
    application.updator=user
    if application.save
        add_environments(application,environments_params) unless environments_params.nil?
        Events::Application::Update.create(account: account, application: application, user: user)
        application.check_application_cost
        status Status, :success, application, &block
    else
        status Status, :validation_error, application.errors.messages, &block
    end
    return application
  end

  def self.delete(organisation, user, application, &block)
    account = organisation.account
    Application.transaction do
      begin
        application.environments.update_all(application_id: nil)
        if application.delete
          Events::Application::Delete.create(account: account, application: application, user: user)
          status Status, :success, application, &block
        else
            status Status, :error, nil, &block
        end
      rescue Exception=>e
        status Status, :error, nil, &block
      end
    end
    return application
  end

  #TODO : Refactor to optimize the process
  def self.add_environments(application,environments_params,&block)
    application.environments=[]
    environments_params.each do |environment_params|
      Environment.where({id: environment_params[:id]}).update_all({application_id: application.id,position: environment_params[:position]})
    end
    status Status, :success, application, &block
    return application
  end

  def self.remove_environments(application,environments_params,&block)
    application.environments=[]
    environments_params.each do |environment_params|
      Environment.where({id: environment_params[:id]}).update_all({application_id: application.id,position: environment_params[:position]})  
    end
    status Status, :success, application, &block
    return application
  end

  def self.reorder_environments(application,environments_params,&block)
    application.environments=[]
    environments_params.each do |environment_params|
      Environment.where({id: environment_params[:id]}).update_all({application_id: application.id,position: environment_params[:position]})  
    end
    status Status, :success, application, &block
    return application
  end

  def self.top_applications(account, &block)
    account = fetch Account, account
    applications = Application.where(account_id: account.id).order(updated_at: :desc).limit(4)

    status Status, :success, applications, &block
    return applications
  end

  def self.get_list(user, organisation, &block)
    account = organisation.account
    user_role_ids = user.user_roles.pluck(:id)
    applications = Application.select(:id,:name).where(account_id: account.id).where("access_roles @> ARRAY['#{user_role_ids.join('\',\'')}']::uuid[] OR access_roles = '{}'").order(name: :asc)
    status Status, :success, applications, &block
    return applications
  end
end
