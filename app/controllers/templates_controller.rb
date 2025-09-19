class TemplatesController < ApplicationController
  authority_actions template_image: 'read', provision_sync_services: 'provision', revisions: 'read', copy_template: 'read', copy_template: 'create', copy_template: 'delete', copy_template_from_revision: 'create', copy_template_info: 'read', update_template_details: 'update', get_overriden_service_tags: 'read', load_revision_data: 'read', generic_directory_services: 'access', create_generic_template: 'access', provision_generic_template: 'access', update_generic: 'access', create_services_tags_on_provider: 'manage'
  authorize_actions_for Template, except:[:index, :directory_services, :show_unallocated_template_services_tags, :list_iam_roles, :show_unallocated_template, :show_unallocated_template_undrawable_services, :dettached_directory_services, :get_security_threats ]
  
   # Commenting instance level authorisation checks

  def index
    authorize_action_with_condition(:index, Template)

    TemplateSearcher.search(current_account, current_tenant, user, page_params, search_params) do |result|
      result.on_success do |templates|
        respond_with templates[0], represent_with: TemplatesDisplayRepresenter, total_records: templates[1]#, location: templates_url
      end
    end
  end

  def show
    @template = Template.find(params[:id])
    #authorize_action_for(@template)

    TemplateSearcher.find(@template) do |result|
      result.on_success { |template| respond_with_user_and template }
      result.on_error   { render body: nil, status: 500 }
    end
  end
  
  def create
    authorize_action_for Template, account_id: current_account.id
    TemplateCreator.create(permit_all_params, current_organisation, user) do |result|
      result.on_success          { |template| 
        template.reusable_services_only = true
        respond_with_user_and template, status: :created 
      }
      result.on_error            { render body: nil, status: 500 }
      result.on_unauthorized     { |id| render json: { message: "Access denied to nested object #{id}" }, status: 403 }
      result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
    end
  end

  def create_generic_template
    authorize_action_for Template, account_id: current_account.id
    TemplateCreator.create(permit_all_params, current_organisation, user) do |result|
      result.on_success          { |template|
        template.reusable_services_only = true
        respond_with_user_and template, status: :created
      }
      result.on_error            { render nothing: true, status: 500 }
      result.on_unauthorized     { |id| render json: { message: "Access denied to nested object #{id}" }, status: 403 }
      result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
    end
  end

  def update
    @template = Template.find(params[:id])
    #authorize_action_for(@template)
    TemplateUpdater.update(current_organisation, @template, permit_all_params, user) do |result|
      result.on_success        { |template| 
        template.reusable_services_only = true
        respond_with_user_and template
      }
      result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
      result.on_error          { |e| render json: { message: "Unable to update template", exception: e.inspect }, status: 422 }
      result.on_unauthorized   { |id| render json: { message: "Access denied to nested object #{id}" }, status: 403 }
    end
  end

  def update_generic
      @template = Template.find(params[:id])
      #authorize_action_for(@template)

      TemplateUpdater.update(current_organisation, @template, permit_all_params, user) do |result|
        result.on_success        { |template|
          template.reusable_services_only = true
          respond_with_user_and template
        }
        result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
        result.on_error          { |e| render json: { message: "Unable to update template", exception: e.inspect }, status: 422 }
        result.on_unauthorized   { |id| render json: { message: "Access denied to nested object #{id}" }, status: 403 }
      end
    end

  def destroy
    @template = Template.find(params[:id])
    #authorize_action_for(@template)

    TemplateDeleter.delete(@template, current_organisation, user) do |result|
      result.on_success { |template| respond_with_user_and template, status: 204 }
      result.on_error   { |e| render json: {}, status: 500 }
    end
  end

  def revisions
    @template = Template.find(params[:id])
    #authorize_action_for(@template)

    Templates::RevisionSearcher.search(@template, user) do |result|
      result.on_success { |revisions| render json: Templates::RevisionsRepresenter.new(revisions), status: 200 }
    end
  end

  def directory_services
    searcher = Service::TemplateDirectoryServicesSearcher.new user,current_account, directory_services_params
    searcher.search do |result|
      result.on_success do  |searched_services|
        is_unallocated = directory_services_params["is_unallocated"]
        services_data = is_unallocated ? [] : searcher.fetch_services_data
        templates_data = is_unallocated ? [] : searcher.fetch_templates_data
        data = [params[:adapter_id]] + searched_services + services_data + templates_data
        respond_with data, represent_with: CategorizedServicesRepresenter
      end
      result.on_error   { |error_msg| render json: { error_msg: error_msg }, status: 400 }
      result.on_validation_error { |error_msgs| render status: 409, json: error_msgs }
    end
  end

  def dettached_directory_services
    searcher = Service::TemplateDirectoryServicesSearcher.new user, current_account, directory_services_params
    searcher.search_dettached(params[:vpc_id], params[:service_type]) do |result|
      result.on_success do  |searched_services|
        data = [params[:adapter_id]] + searched_services
        respond_with data, represent_with: CategorizedServicesRepresenter
      end
      result.on_error   { |error_msg| render json: { error_msg: error_msg }, status: 400 }
      result.on_validation_error { |error_msgs| render status: 409, json: error_msgs }
    end
  end  

  def list_iam_roles
    iam_roles = Service::IamRoleFetcher.get_iam_roles(params[:adapter_id])
    data = { iam_roles: iam_roles }
    if params[:service_id]
      service = Service.find(params[:service_id])
      selected_role = service.get_selected_iam_role
      data.merge!(role: selected_role) if selected_role
    end
    render json: data
  end

  def provision
    @template = Template.find(params[:id])
    #authorize_action_for(@template)
    TemplateProvisioner.provision(@template, user, current_tenant, current_organisation, provision_params) do |result|
      result.on_success { |env| render json: { id: env.id }, status: 200 }
      result.on_error   { |e| render json: { message: "Failed to provision template to environment!", exception: e.inspect }, status: 422 }
      result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
    end 
  end

  def provision_generic_template
    @template = Template.find(params[:id])
    #authorize_action_for(@template)
    TemplateProvisioner.provision(@template, user, current_tenant, current_organisation, generic_template_provision_params(current_organisation, user)) do |result|
      result.on_success { |env| render json: { id: env.id }, status: 200 }
      result.on_error   { |e| render json: { message: "Failed to provision template to environment!", exception: e.inspect }, status: 422 }
      result.on_validation_error { |error_msgs| render status: 422, json: {validation_error: error_msgs} }
    end
  end

  def provision_sync_services
    TemplateProvisioner.provision_sync_services(current_organisation, user, permit_all_params) do |result|
      result.on_success { |env| render json: { id: env.id }, status: 200 }
      result.on_error   { |e| render json: { message: "Failed to provision template to environment!", exception: e.inspect }, status: 422 }
      result.on_validation_error { |error_msgs| render status: 400, json: {validation_error: error_msgs} }
    end
  end

  def template_image
    # ImageService.save_image(params[:id], 'templates', user, environment_id: params[:environment_id])
    render json: { success: true }
  end

  def show_unallocated_template
    tag_filters = params[:tag_filters] ? JSON.parse(params[:tag_filters]) : {}
    tag_operator = params[:tag_operator] ? params[:tag_operator] : "OR"
    TemplateCreator.init_unallocated(params[:vpc_id], params[:page_name], current_organisation,tag_filters, tag_operator) do |result|
      result.on_success { |template| respond_with_user_and template }
      result.on_region_disabled { render json: {message: "Cannot view unallocated environment from a disabled region"}, status: 401 }
      result.not_found  { render status: 404, json: cloudstreet_error(:vpc_not_found) }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def show_unallocated_template_undrawable_services
    tag_filters = params[:tag_filters] ? JSON.parse(params[:tag_filters]) : {}
    tag_operator = params[:tag_operator] ? params[:tag_operator] : "OR"
    TemplateCreator.init_unallocated_undrawable(params[:vpc_id], params[:page_name], current_organisation, tag_filters, tag_operator) do |result|
      result.on_success { |template| respond_with_user_and template }
      result.on_region_disabled { render json: {message: "Cannot view unallocated environment from a disabled region"}, status: 401 }
      result.not_found  { render status: 404, json: cloudstreet_error(:vpc_not_found) }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def show_unallocated_template_services_tags
    TemplateCreator.unallocated_services_tags(params[:vpc_id], params[:page_name], current_organisation) do |result|
      result.on_success { |service_tags| render json: { tags_map: service_tags }, status: 200 }
      result.on_region_disabled { render json: {message: "Cannot view unallocated environment from a disabled region"}, status: 401 }
      result.not_found  { render status: 404, json: cloudstreet_error(:vpc_not_found) }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def create_services_tags_on_provider
    TemplateCreator.create_services_tags_on_provider(permit_all_params, current_account, current_organisation)do |result|
      result.on_success { |service| render json: service, status: 200 }
      result.not_found  { |message| render json: { message: message }, status: 404 }
      result.on_error   { |message| render json: {message: message}, status: 500 }
    end
  end

  def copy_template
    authorize_action_for Template, account_id: current_account.id
    
    @template = Template.find(params[:id])
    #authorize_action_for(@template)

    TemplateCopier.copy_from_template(@template, user, params[:name])do |result|
      result.on_success { |template| respond_with_user_and template }
      result.on_error   { render body: nil, status: 500 }
      result.on_validation_error { |error_msgs| render status: 400, json: {validation_error: error_msgs} }
    end
  end

  def copy_template_from_revision
    # copy from environment revision
    authorize_action_for Template, account_id: current_account.id    

    TemplateCopier.copy_from_environment_revision(user, current_organisation, params) do |result|
      result.on_success { |template| respond_with_user_and template[0], template_errors: template[1] }
      result.on_error   { render body: nil, status: 500 }
      result.on_validation_error { |error_msgs| render status: 400, json: {validation_error: error_msgs} }
    end
  end 

  def copy_template_info
    TemplateCopierInitialiser.new_template(params, current_account, user) do |result|
      result.on_success { |data| respond_with_user_and data, represent_with: Templates::InitialiserRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def load_revision_data   
    #TODO - generic for the service type provided
    template = Template.find(params[:id])
    #authorize_action_for(template)
    TemplateSearcher.get_revision_data(params[:id], params[:revision]) do |result|
      result.on_success { |revision_data| render json: revision_data, status: 200 }
      result.on_error   { |err| render json: err, status: 500 }
    end
  end

  # updates template attributes such as name, description
  def update_template_details
    template = Template.find(params[:id])
    #authorize_action_for(template)
    TemplateUpdater.update_template_details(template, update_template_details_params, user) do |result|
      result.on_success { |template| respond_with_user_and template, represent_with: TemplateInfoRepresenter }
      result.on_error   { render body: nil, status: 500 }
    end
  end

  def get_overriden_service_tags    
    template = Template.find(params[:id])
    #authorize_action_for(template)
    TemplateServiceTagsFetcher.fetch_overridden_tags(template, params) do |result|
      result.on_success { |overridden_tags| render json: {overridden_tags: overridden_tags}, status: 200 }
    end
  end

  def get_security_threats
    tag_filters = params[:tag_filters] ? JSON.parse(params[:tag_filters]) : {}
    TemplateCreator.get_security_threats( params[:vpc_id],params[:adapter_id], current_organisation,tag_filters) do |result|
      result.on_success { |result| render json: {result: result}, status: 200 }
    end
  end

  def generic_directory_services
    searcher = Service::GenericTemplateDirectoryServicesSearcher.new user, current_account, directory_services_params
    searcher.search do |result|
      result.on_success do  |searched_services|
        services_data = false ? [] : searcher.fetch_services_data
        templates_data = false ? [] : searcher.fetch_templates_data
        data = searched_services + services_data + templates_data
        respond_with data, represent_with: CategorizedServicesRepresenter
      end
      result.on_error   { |error_msg| render json: { error_msg: error_msg }, status: 400 }
      result.on_validation_error { |error_msgs| render status: 409, json: error_msgs }
    end
  end

private

  def directory_services_params
    params.permit(:adapter_id, :region_id, :vpc_id).to_h.tap do |white_listed|
      white_listed[:is_unallocated] = (params[:is_unallocated] == 'true' || params[:is_unallocated] == true) ? true : false
    end
  end

  def provision_params
    params.permit(:name, :id, :auto_start_env, :naming_exception, :privateip_exception, :selected_type, :application_id, :provision_from_listing).to_h.tap do |white_listed|
      white_listed[:tags] = params[:tags]
      white_listed[:template_tags] = params[:template_tags]
    end
  end
  
  def generic_template_provision_params(organisation, user)
    params[:account_id] = organisation.account.try(:id)
    params.permit(:name, :id, :auto_start_env, :naming_exception, :privateip_exception, :selected_type, :application_id, :provision_from_listing, :adapter_id, :account_id).tap do |white_listed|
      white_listed[:tags] = params[:tags]
      white_listed[:template_tags] = params[:template_tags]
    end
  end

  def search_params
    params.permit(:name, :adapter_id, :region_id, :to_date, :from_date, :state, :provider, :access, :template_type).to_h
  end

  def update_template_details_params
    params.permit(:id, :name, :description).to_h
  end

  def permit_all_params
    params.permit!
    params.to_h
  end

end
