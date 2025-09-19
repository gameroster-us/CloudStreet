class SoeScripts::GroupsService < CloudStreetService
  class << self

    def list_all(account, filters, &block)
      groups = account.soe_scripts_groups
      filters.slice!(:page, :limit).each do |key, value|
        groups = groups.public_send(key, value) if value.present?
      end
      status Status, :success, groups.select(:name,:id), &block
    end

    def create(source, params, &block)
      group = source.soe_scripts_groups.find_or_initialize_by(id: params[:id])
      group.attributes = params
      if group.save
        status Status, :success, group, &block
      else
        status Status, :validation_error, group.errors.messages, &block
      end
    end

    def copy(account, params, &block)
      group = SoeScripts::Group.where(sourceable: account.soe_scripts_remote_sources.pluck(:id)+[account.id]).find_or_initialize_by(id: params[:id])
      if group
        new_group = group.dup
        (
          if params[:soe_script_id].present?
            group.soe_scripts.where(id: params[:soe_script_id]).all
          else
            group.soe_scripts
          end
        ).each do|script|
          new_group.soe_scripts.build(script.dup.attributes)
        end
        # counter = ((source.soe_scripts_groups.where('name ~* :pat', :pat => '\Acopy of.+[0-9]+\M').order("name desc").pluck(:name).first.split(/copy of [^0-9]+/).last) rescue SecureRandom.random(5))
        rand = SecureRandom.random_number(99999)
        new_group.name = "copy of #{new_group.name} #{rand}"
        new_group.sourceable_id = account.id
        new_group.sourceable_type = "Account"
        if new_group.save(validate: false)
          status Status, :success, new_group, &block
        else
          status Status, :validation_error, new_group.errors.messages, &block
        end
      end
    end

    def find(account, id, &block)
      soe_scripts_group = account.soe_scripts_groups.find_by(id: id)
      if soe_scripts_group.present?
        status Status, :success, soe_scripts_group, &block
      else
        CSLogger.info('Soe script group not present')
        CSLogger.info soe_scripts_group.inspect
        CSLogger.error soe_scripts_group.try(:errors)
        status Status, :error, soe_scripts_group, &block
      end
    rescue StandardError => e
      CSLogger.error "Error in find Soe script group = #{e.message}"
      CSLogger.error e.backtrace
      status Status, :error, nil, &block
    end

    def update(source, params, &block)
      soe_scripts_group = source.soe_scripts_groups.find_by_id(params[:id])
      if soe_scripts_group
        if soe_scripts_group.update(params)
          status Status, :success, soe_scripts_group, &block
        else
          status Status, :validation_error, soe_scripts_group.errors.messages, &block
        end
      else
        status Status, :not_found, nil, &block
      end
    end

    def destroy(source, group_id, &block)
      source.soe_scripts_groups.where(id: group_id).delete_all
      MachineImageConfigurationsSoeScript.where(soe_script: SoeScript.where(soe_scripts_group_id: group_id)).delete_all
      status Status, :success, nil, &block
    end
  end
end
