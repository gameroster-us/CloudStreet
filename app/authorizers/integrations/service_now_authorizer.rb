# frozen_string_literal: true

# authorizing service now integrations actions
class Integrations::ServiceNowAuthorizer < ApplicationAuthorizer
  def self.default(adjective, user)
    false
  end

  def self.readable_by?(user)
    user.is_permission_granted?('cs_integrations_service_now_workspace_view')
  end

  def self.provisionable_by?(user)
    user.is_permission_granted?('cs_integrations_service_now_authenticate')
  end

  def self.updatable_by?(user)
    user.is_permission_granted?('cs_integrations_service_now_workspace_update')
  end

  def self.manageable_by?(user)
    user.is_permission_granted?('cs_integrations_service_now_update')
  end

  def self.deletable_by?(user)
    user.is_permission_granted?('cs_integrations_service_now_workspace_delete')
  end
end
