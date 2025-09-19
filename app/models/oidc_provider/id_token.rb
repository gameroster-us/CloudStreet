# frozen_string_literal: true

class OIDCProvider::IdToken < ApplicationRecord
  # PASSPHRASE_ENV_VAR = 'OIDC_PROVIDER_KEY_PASSPHRASE'
  PASSPHRASE_ENV_VAR = 'CSMP_OIDC_PASS'

  belongs_to :authorization, class_name: "OIDCProvider::Authorization"

  attribute :expires_at, :datetime, default: -> { 1.hour.from_now }

  delegate :account, to: :authorization

  def to_response_object
    client = OIDCProvider::Client.find_by(identifier: authorization.client_id)
    issuer = client.organisation.host_url
    OpenIDConnect::ResponseObject::IdToken.new(
      iss: issuer,
      sub: account.id,
      aud: authorization.client_id,
      nonce: nonce,
      exp: expires_at.to_i,
      iat: created_at.to_i
    )
  end

  def to_jwt
    to_response_object.to_jwt(self.class.private_jwk)
  end

  private

  class << self
    issuer = "#{ENV["WEB_PROTOCOL"]}//#{ENV["WEB_HOST"]}:#{ENV["API_PORT"]}"
    def config
      {
        issuer: issuer,
        jwk_set: JSON::JWK::Set.new(public_jwk)
      }
    end

    def oidc_provider_key_path
      ENV.fetch('OIDC_PROVIDER_PRIVATE_KEY_PATH', Rails.root.join('lib/oidc_provider_key.pem'))
    end

    def key_pair
      @key_pair ||= OpenSSL::PKey::RSA.new(File.read(oidc_provider_key_path), ENV[PASSPHRASE_ENV_VAR])
    end

    def private_jwk
      JSON::JWK.new key_pair
    end

    def public_jwk
      JSON::JWK.new key_pair.public_key
    end
  end
end
