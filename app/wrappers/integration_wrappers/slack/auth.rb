module IntegrationWrappers::Slack::Auth

  def authenticate code
  		filters = {"code" => code, "redirect_uri" => (IntegrationWrappers::Slack.public_auth_api ), "client_id" => IntegrationWrappers::Slack::CLIENT_ID, "client_secret" => IntegrationWrappers::Slack::CLIENT_SECRET}
	    # retry_on_timeout {
	    return self.http_process(IntegrationWrappers::Slack::BASE_URL,'oauth.v2.access','POST',filters,{})
	  # }
  end
end