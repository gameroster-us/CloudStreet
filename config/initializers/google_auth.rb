# config/initializers/google_auth_patch.rb

module Google
  module Auth
    # Overriding ServiceAccountCredentials
    class ServiceAccountCredentials < Signet::OAuth2::Client
      TOKEN_CRED_URI = 'https://www.googleapis.com/oauth2/v4/token'.freeze
      extend CredentialsLoader
      extend JsonKeyReader

      def self.make_creds(options = {})
        json_key_io, scope, json_key = options.values_at(:json_key_io, :scope, :json_key)
        if json_key
          private_key, client_email = extract_json_key(json_key)
        elsif json_key_io
          private_key, client_email = read_json_key(json_key_io)
        else
          private_key = unescape ENV[CredentialsLoader::PRIVATE_KEY_VAR]
          client_email = ENV[CredentialsLoader::CLIENT_EMAIL_VAR]
        end

        new(token_credential_uri: TOKEN_CRED_URI,
            audience: TOKEN_CRED_URI,
            scope: scope,
            issuer: client_email,
            signing_key: OpenSSL::PKey::RSA.new(private_key))
      end

      def self.unescape(str)
        str = str.gsub '\n', "\n"
        str = str[1..-2] if str.start_with?('"') && str.end_with?('"')
        str
      end

      def initialize(options = {})
        super(options)
      end

      def apply!(a_hash, opts = {})
        unless scope.nil?
          super
          return
        end

        cred_json = {
          private_key: @signing_key.to_s,
          client_email: @issuer
        }
        key_io = StringIO.new(MultiJson.dump(cred_json))
        alt = ServiceAccountJwtHeaderCredentials.make_creds(json_key_io: key_io)
        alt.apply!(a_hash)
      end

      def self.extract_json_key(json_key)
        hash_key = JSON.parse(json_key)
        private_key = hash_key['private_key']
        client_email = hash_key['client_email']
        [private_key, client_email]
      end
    end

    # Overriding ServiceAccountJwtHeaderCredentials
    class ServiceAccountJwtHeaderCredentials
      JWT_AUD_URI_KEY = :jwt_aud_uri
      TOKEN_CRED_URI = 'https://www.googleapis.com/oauth2/v4/token'.freeze
      SIGNING_ALGORITHM = 'RS256'.freeze
      EXPIRY = 60
      extend CredentialsLoader
      extend JsonKeyReader

      def self.make_creds(*args)
        new(json_key_io: args[0][:json_key_io])
      end

      def initialize(options = {})
        json_key_io = options[:json_key_io]
        if json_key_io
          private_key, client_email = self.class.read_json_key(json_key_io)
        else
          private_key = ENV[CredentialsLoader::PRIVATE_KEY_VAR]
          client_email = ENV[CredentialsLoader::CLIENT_EMAIL_VAR]
        end
        @private_key = private_key
        @issuer = client_email
        @signing_key = OpenSSL::PKey::RSA.new(private_key)
      end

      def apply!(a_hash, opts = {})
        jwt_aud_uri = a_hash.delete(JWT_AUD_URI_KEY)
        return a_hash if jwt_aud_uri.nil?
        jwt_token = new_jwt_token(jwt_aud_uri, opts)
        a_hash[AUTH_METADATA_KEY] = "Bearer #{jwt_token}"
        a_hash
      end

      def apply(a_hash, opts = {})
        a_copy = a_hash.clone
        apply!(a_copy, opts)
        a_copy
      end

      def updater_proc
        lambda(&method(:apply))
      end

      protected

      def new_jwt_token(jwt_aud_uri, options = {})
        now = Time.new
        skew = options[:skew] || 60
        assertion = {
          'iss' => @issuer,
          'sub' => @issuer,
          'aud' => jwt_aud_uri,
          'exp' => (now + EXPIRY).to_i,
          'iat' => (now - skew).to_i
        }
        JWT.encode(assertion, @signing_key, SIGNING_ALGORITHM)
      end
    end
  end
end
