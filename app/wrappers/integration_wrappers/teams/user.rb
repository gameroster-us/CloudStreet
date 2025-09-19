# frozen_string_literal: true

# Teams user apis
module IntegrationWrappers::Teams::User
  def authenticate(code)
    filters = { 'code' => code, 'redirect_uri' => IntegrationWrappers::Teams.public_auth_api, 'client_id' => IntegrationWrappers::Teams::CLIENT_ID, 'client_secret' => IntegrationWrappers::Teams::CLIENT_SECRET, 'grant_type' => 'authorization_code' }
    self.http_process(IntegrationWrappers::Teams::TEAMS_AUTH_URL, '/organizations/oauth2/v2.0/token', 'POST', filters, {})
  end
end
