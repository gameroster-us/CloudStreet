require 'engine/backgroundable'
# require 'engine/event/environment'
# require 'engine/workflow/environment'
# require 'engine/metrics'

# Context for Environment operations
module Engine
  #
  class Environment # < Backgroundable
    attr_reader :environment, :user

    def self.create_from_template(template, user)
      CSLogger.info "CREATING ENVIRONMENT FROM TEMPLATE YO (provisioning)"

      e = ::Environment.new(name: template.name, template: template)

     template.services.each do |s|
      CSLogger.info s.inspect
       e.services << s.dup
     end

      e.save!
      CSLogger.info "------------"
    end

    def initialize(environment, user)
      @environment = environment
      @user        = user
    end

    def provision
      CSLogger.info "CloudStreet::Engine::Environment::Provision"
      # Engine::Logger.debug "CloudStreet::Engine::Environment::Provision"
      Engine::Events::Environment.provision(environment, user)
      Engine::Workflow::Environment.provision(environment)
      Engine::Metrics.increment "CloudStreet.engine.environment.provision"
    end
  end
end
