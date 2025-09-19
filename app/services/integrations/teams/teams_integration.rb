# frozen_string_literal: true

# Teams integration
module Integrations::Teams::TeamsIntegration
  # encapsulate class methods
  module ClassMethods
    def show_teams_integration(params, &block)
      show(params, &block)
    end

    def update_teams_configuration(params, &block)
      update(params, &block)
    end
  end

  # encapsulate instance methods
  module InstanceMethods
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
