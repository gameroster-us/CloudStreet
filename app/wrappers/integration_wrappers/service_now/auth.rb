# frozen_string_literal: true

# authorizing service now integrations
module IntegrationWrappers::ServiceNow::Auth
  # Class methods
  module ClassMethods
    # use before storing.decrypted data accepted
    def verify(instance_id, client_id, client_secret, username, password)
      begin
        client = ServiceNow::Client.authenticate(instance_id, client_id, client_secret, username, password)
        { 'ok' => true, 'client' => client }
      rescue => e
        if e.response.class == Faraday::Response
          error = e.response.body
          error = "Access denied: Wrong instance id or instance is hibernating." if error.class == String && e.response.body.include?("Your instance is hibernating")
        else
          error = 'Access denied: Provided credentials are Invalid'
        end
        { 'ok' => false, 'error' => error }
      end
    end
  end

  # Intsnace methods
  module InstanceMethods
    # will always use stored encrypted data accepted only
    def get_client
      begin
        client = ServiceNow::Client.authenticate(@workspace.instance_id, @workspace.client_id, decrypt_value(@workspace.client_secret), @workspace.username, decrypt_value(@workspace.password))
        { 'ok' => true, 'client' => client }
      rescue => e
        if e.response.class == Faraday::Response
          error = e.response.body
          error = "Access denied: Wrong instance id or instance is hibernating." if error.class == String && e.response.body.include?("Your instance is hibernating")
        else
          error = 'Access denied: Provided credentials are Invalid'
        end
        { 'ok' => false, 'error' => error }
      end
    end
  end

  def self.included(receiver)
    receiver.extend         ClassMethods
    receiver.send :include, InstanceMethods
  end
end
