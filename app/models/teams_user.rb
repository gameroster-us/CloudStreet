# frozen_string_literal: true

# Teams integration actions
class TeamsUser < ApplicationRecord
  include Integrations::Agents
  
  belongs_to :workspace
  belongs_to :user
  belongs_to :organisation
  belongs_to :account
  
  validates :access_token, :aad_object_id, :user_id, :account_id, :organisation_id, presence: true
  validates :user_id, :uniqueness => { :scope => [:workspace_id, :organisation_id] }, if: lambda{ try(:user_id).present? }
  
  scope :find_user_in_workspace, -> (user, workspace, organisation, aad_object_id) {where("organisation_id='#{organisation.id}' and workspace_id='#{workspace.id}' and 'aad_object_id'='#{aad_object_id}' and user_id='#{user.id}'").group('id').last }
  scope :get_single_user_records_with_no_bot_data, -> (aad_object_id) { where("aad_object_id = '#{aad_object_id}'").where("conversation_data::text = '{}'::text or service_url::text = '{}'::text or user_data::text = '{}'::text or bot_data::text = '{}'::text") } 
  scope :get_by_integrations_ids, -> (integrations_ids){ joins(workspace: [:integrations]).where('integrations.id in (?)', Integrations_ids).group('id') }

  scope :find_by_aad_user_id, -> (auid){where("user_details ->> 'id'='#{auid}'").last}
  
  def bot_data_present?
    conversation_data.present? && bot_data.present? && user_data.present? && service_url.present?
  end

  def aad_user_id
    user_details["id"]
  end

  def display_name
    user_details.to_h["displayName"]
  end

end

