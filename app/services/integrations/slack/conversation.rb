class Integrations::Slack::Conversation < CloudStreetService
	extend Integrations::Agents
	
	class << self
	
		def conversation_list(organisation, user, params, &block)
			workspace = Workspace.find_by(id: params[:id])
			return status Status, :error, "Something went wrong.", &block if [organisation, workspace, user].any? { |obj| obj.class.name == "NilClass" }
			slack_user = SlackUser.configured_user_slack_account_in_workspace organisation, workspace, user
			return status Status, :error, "Something went wrong.", &block unless slack_user.present? && slack_user.try(:access_token).present?
			body = {}
			channels_data = []
			first_hit = true
			data = {}
			next_cursor = ""
			while first_hit || (data.present? && data["response_metadata"].present? && data["response_metadata"]["next_cursor"].present?)
				body = {"cursor" => next_cursor} if next_cursor.present?
				data = workspace.slack_workspace_agent.user_conversations slack_user.access_token, body
				next_cursor = data["response_metadata"].present? ? data["response_metadata"]["next_cursor"] : ""
				channels_data << data["channels"]
				first_hit = false if first_hit
			end
			channels_data = channels_data.flatten.compact.uniq
			if data["ok"] == true && data["error"].blank?
				return status Status, :success, channels: channels_data, &block
			else
				return status Status, :error, "Something went wrong.", &block
			end
		end

	end

end