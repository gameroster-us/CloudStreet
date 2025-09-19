class Integrations::AuthService < CloudStreetService
	include Adapters::Helpers::Common #openssl
	include Integrations::Slack::SlackAuth
	include Integrations::Teams::TeamsAuth
	include Integrations::ServiceNow::ServiceNowAuth
end