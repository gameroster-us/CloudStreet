class OrganisationImageService < CloudStreetService

  def self.create(account, params, &block)
    ActiveRecord::Base.transaction do
      account = fetch Account, account
      region = fetch Region, params[:region_id]
      machine_image = MachineImage.findami(params[:image_id], region.code)
      organisation_image = OrganisationImage.find_or_create_by(id: params[:id])
      params[:machine_image_configurations_attributes] = params.delete(:machine_image_configurations)
      machine_image_configuration_ids = []
      (params[:machine_image_configurations_attributes]||[]).each{|m|
        machine_image_configuration_ids << m["id"]
        config_script_join_ids = (m["machine_image_configurations_soe_scripts_attributes"]||{}).values.collect{|obj| obj["id"]}
        MachineImageConfigurationsSoeScript.where(machine_image_configuration_id: m["id"]).where.not(id: config_script_join_ids).delete_all
      }
      params["account_id"] = account.id
      organisation_image.attributes = params
      unless machine_image.blank?
        organisation_image.create_org_image_obj(machine_image)
        organisation_image.machine_image_name = machine_image.name
        if machine_image.is_public.eql?('f')
          organisation_image.is_public = false
          organisation_image.machine_image_id = machine_image.id
          organisation_image.machine_image_group_id = machine_image.machine_image_group_id
        else
          organisation_image.is_public = true
        end
        organisation_image.active = true
        updating = organisation_image.updating_record?
        if organisation_image.save
          if updating
            update_dependent_resources(organisation_image)
          end # && organisation_image.changed_attributes.keys.include?('image_id')
          status Status, :success, organisation_image, &block
        else
          status Status, :validation_error, organisation_image, &block
        end
      end
    end
  rescue CentralApiNotReachable => e
    CSLogger.error(e.class)
    CSLogger.error(e.message)
    CSLogger.error(e.backtrace)
    Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
    status Status, :central_api_error, {error: e.message}, &block
  rescue Exception => e
    CSLogger.error(e.class)
    CSLogger.error(e.message)
    CSLogger.error(e.backtrace)
    Honeybadger.notify(e) if ENV["HONEYBADGER_API_KEY"]
    status Status, :error, nil, &block
  end

  def self.update_dependent_resources(org_image)
    updatable_services = Service.where( 
                  account_id: org_image.account_id,
                  region_id: org_image.region_id,
                  state: [:template, :environment, :pending, :archived],
                  type: ['Services::Network::AutoScalingConfiguration::AWS', 'Services::Compute::Server::AWS']
                  ).where("data ->> 'image_config_id' IN (?) ", org_image.machine_image_configurations.pluck(:id))
    if updatable_services.present?
      updatable_services.each do |updatable_service|
        updatable_service.image_id = org_image.image_id
        updatable_service.data_will_change!
        updatable_service.save!
      end
    end
  end

  def self.verify_compatibility(user, organisation, params, &block)
    organisation_image = organisation.account.organisation_images.find(params[:id])
    organisation_image.image_id = params[:image_id]
    reponse  = OrgImageUpdateValidator.new(organisation_image).validate if organisation_image.changed_attributes.keys.include?('image_id')
    if reponse.kind_of?(Array)
      status Status, :validation_error, reponse.first, &block
    elsif reponse.nil?
      status Status, :success, organisation_image, &block     
    else      
      status Status, :success, reponse, &block      
    end
    return reponse
    # old_soe = organisation_image.machine_image
    # new_soe = MachineImage.where({
    #     region_id: organisation_image.region_id, 
    #     image_id: params[:image_id]
    #   }).first
    #New SOE exists in Amazon
      #New SOE is private but not fetched
    #match OLD and NEW attributes
  rescue CentralApiNotReachable => e
    CSLogger.error(e.class)
    CSLogger.error(e.message)
    CSLogger.error(e.backtrace)
    status Status, :central_api_error, {error: e.message}, &block
  end

  def self.find(user, account, id, &block)
    image = user.get_accessible_amis(account).find_by_id(id)
    if image
      status Status, :success, image, &block
    else
      status Status, :not_found, nil, &block
    end
    return image
  end

  def self.remove_image(user, account, image_id, &block)
    image = user.get_accessible_amis(account).find_by(id: image_id)
    if image.destroy
      status Status, :success, image, &block
    else
      status Status, :error, image, &block
    end
    return image
  end

  def self.find_all(account, page_params, filters={}, &block)
    images = OrganisationImage.where({account_id: account.id,region_id: filters["region_id"]})
    images = images.filter_by_keywords(filters["keywords"]) unless filters["keywords"].blank?
    images = images.order('updated_at DESC NULLS LAST')

    images, total_records = apply_pagination(images, page_params)
    #TODOSOE filter keywords and filter by aws provider
    status Status, :success, { total_records: total_records, images: images }, &block
    return images
  end

end
