# frozen_string_literal: true

# Teams notification integration
module Integrations::Teams::TeamsNotification
  # encapsulate class methods
  module ClassMethods
  end
  # encapsulate instance methods
  module InstanceMethods
    # data = {"text" => "hi how are you?", "attachments" => "array/hash", "blocks" => [] }
    def post_to_teams_by_roles(options)
      validate_json_format options
      intgs = teams_integrations
      return "No teams integration found for roles '#{@user_role_ids.join(", ")}' in '#{@organisation.try(:name)}' organisation." if intgs.blank?

      return 'No integrations found.' if intgs.blank?

      # bot_token = IntegrationWrappers::Teams.generate_bot_token
      bot_token = IntegrationWrappers::Teams.generate_bot_token
      result = {}
      intgs.each do |integration|
        begin
          retries ||= 0
          teams_user = integration.workspace.teams_user
          next unless teams_user.bot_data_present?
          data = integration.workspace.teams_user.teams_agent.post_message bot_token, options
          raise data['message'] if data['message'] == 'Authorization has been denied for this request.'
          result[integration.id] = data
        rescue
          CSLogger.info 'in rescueeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee'
          bot_token = IntegrationWrappers::Teams.generate_bot_token
          retry if (retries += 1) < 2
        end
      end
      return result
    end

    def teams_integrations
      integrations.teams.group('id')
    end

    def get_user_ids_by_organisation_roles
      User.joins(:user_roles).where(user_roles: {id: @user_role_ids}).pluck(:id).uniq
    end

    # def teams_integrations
    #   integrations.teams.includes(workspace: [:teams_user])
    # end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
