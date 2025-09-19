class Integrations::SlackAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user)
    false
  end
  
  def self.readable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_workspace_view')
  end

  def self.visualizable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_channel_view')
  end

  def self.provisionable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_authenticate')
  end

  def self.creatable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_channel_create')
  end

  def self.updatable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_channel_update')
  end

  def self.deletable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_channel_delete')
  end

  def self.accessible_by?(user)
    user.is_permission_granted?('cs_integrations_slack_workspace_delete')
  end

  def self.manageable_by?(user)
    user.is_permission_granted?('cs_integrations_slack_channel_config')
  end
end
