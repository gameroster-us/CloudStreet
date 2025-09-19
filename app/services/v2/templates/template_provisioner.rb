module V2
  module Templates
    class TemplateProvisioner < CloudStreetService
      class << self
        def provision(template, organisation, user, params, &block)
          template = fetch Template, template
          @user = user = fetch User, user
          account  = organisation.account
          name     = params[:name]
          template.naming_exception = params[:naming_exception]
          template.application_id = params[:application_id]
          selected_type = params[:selected_type].nil? ? 2 : params[:selected_type]
          status Status, :unauthorized, account.id, &block and return unless user.can_provision?(template)
          return if validate_environment(template, &block)["error"].present?
          CSLogger.info "Provisioning template #{template.id} to #{name} by user #{user.username}"
          environment = create_environment(account, template, user, name, selected_type, &block) #create
          return if environment.blank?
          V2::Environments::EnvironmentStarter.start!(environment, user.id){} if params[:auto_start_env] #start
          begin
            environment.reload
            ImageService.copy_s3_to_s3(template.id, environment.id, "template", "environment")
          rescue Exception => e
            CSLogger.error("#{e.class} #{e.message} #{e.backtrace}")
          end
          yield Status.success(environment) if block_given?
          return environment
        end

        def validate_environment(template, &block)
          # TODO move this code to provider specific validator class
          CSLogger.info "template==== #{template.inspect}"
          arm_template_hash = Azure::Resource::ResourceGroup.create_arm_deployable_template(template.CS_services)
          CSLogger.info "template arm_template_hash--- #{arm_template_hash}"
          vnet = template.CS_services.where(service_type: "Azure::Network::Vnet").first
          CSLogger.info "vnet== #{vnet.inspect}"
          rg = Azure::Network::Vnet.find_by_CS_service_id(vnet.id).resource_group
          validation_res = JSON.parse(rg.validate_deployable_template(arm_template_hash).to_json)
          CSLogger.error "validation_res: #{validation_res}"
          if validation_res["error"].present?   
            error = validation_res["error"]
            status Status, :validation_error, "#{validation_res["error"]["code"]}: #{validation_res["error"]["message"]}", &block
          end
          validation_res
        end

        # can be moved to somewhere else
        def create_environment(account, template, user, name, selected_type,  &block)
          environment = nil
          errors = nil
          begin
            ActiveRecord::Base.transaction do
              environment = V2::Environments::EnvironmentTemplatable.create_from_template(account, template, user, name, selected_type)
              errors = environment.errors.messages
              raise ActiveRecord::Rollback unless environment.valid?
              CSLogger.error "errors::"
            end
          rescue => e
            CSLogger.error "-------#{e.inspect} \n #{e.backtrace.join("\n")}"
            errors = {error: e.message}
          end
          if errors.present?
            errors.each { |k,v| errors[k] = ["Environment #{k} #{v.try(:first)}"]}
            status Status, :validation_error, errors.merge(environment_error: true), &block
            return
          end
          environment.save!
          CSLogger.info "create_environment success==========================="
          environment
        end
      end
    end
  end
end
