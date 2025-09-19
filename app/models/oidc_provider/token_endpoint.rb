# frozen_string_literal: true

module OIDCProvider
  class TokenEndpoint
    attr_accessor :app

    delegate :call, to: :app

    def initialize
      CSLogger.info "======token end point called!!!"
      CSLogger.info "Client ID: #{req.client_id}"
      CSLogger.info "Client secret: #{req.client_secret}"
      CSLogger.info "Redirect URI: #{req.redirect_uri}"
      @app = Rack::OAuth2::Server::Token.new do |req, res|
        CSLogger.info "Client ID: #{req.client_id}"
        CSLogger.info "Client secret: #{req.client_secret}"
        CSLogger.info "Redirect URI: #{req.redirect_uri}"

        client = find_valid_client_from(req) || req.invalid_client!

        CSLogger.info 'Found a client!'

        case req.grant_type
        when :authorization_code
          CSLogger.info 'Grant type was an authorization code. Correct!'
          authorization = OIDCProvider::Authorization.valid.where(client_id: client.identifier, code: req.code).first || req.invalid_grant!
          CSLogger.info 'We found an authorization matching this code!'
          res.access_token = authorization.access_token.to_bearer_token
          res.id_token = authorization.id_token.to_jwt if authorization.scopes.include?('openid')
        else
          CSLogger.info "Unsupported grant type: #{req.grant_type.inspect}"
          req.unsupported_grant_type!
        end
      end
    end

    private

    def find_valid_client_from(req)
      client = OIDCProvider::Client.find_by(
        identifier: req.client_id,
        secret: req.client_secret
      )

      return nil unless client

      client.redirect_uri.include?(req.redirect_uri) ? client : nil
    end
  end
end
