# frozen_string_literal: true

# Teams slack workspace model
class Workspaces::Slack < Workspace
  validate :data_field
  validate :slack_workspace_uniqueness_in_organisation,if: lambda { organisation.present? && data_changed? && data.to_h['access_token'].present? && data.to_h['access_token'] != data_was.to_h['access_token']}

  #after_create :fetch_users_from_workspace, if: lambda { try(:access_token).present? }

  Data_instance_methods = [:app_id, :authed_user, :scope, :token_type, :access_token, :bot_user_id, :team, :enterprise, :incoming_webhook]

  Data_instance_methods.each do |method|
    define_method method do
      data.to_h[method.to_s]
    end
  end

	def data_field
    return errors.add(:base, "data can't be blank") if data.nil?
    return errors.add(:base, "access_token can't be blank") if access_token.blank?
  end
		
  def slack_workspace_uniqueness_in_organisation
    return errors.add(:base, "This workspace is already added.") if self.class.where("data ->> 'access_token' = '#{data["access_token"]}' and organisation_id='#{organisation_id}'").exists?
  end
	
  def fetch_users_from_workspace
    options = {'workspace_id' => id, 'organisation_id' => organisation_id}
    Integrations::SlackWorkers::UsersListWorker.perform_async options
  end

  class << self
    def active
      super
    end
  end
end
