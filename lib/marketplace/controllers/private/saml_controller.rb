module Private
  class SamlController < ApplicationController
    # skip_before_action :verify_authenticity_token, :only => [:acs, :logout]

    represents :json, entity: AuthenticationRepresenter

    def index
      @attrs = {}
    end

    def acs
      settings = AccountSamlSetting.get_saml_settings(get_url_base)
      response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings)

      attrs = {}
      response.attributes.each{|k,v| attrs[k] = v}
      @session = SessionCreator.saml_login(response.nameid, attrs) 
      if @session
        CSLogger.info "authenticated!!!"
        @user = @session.user
        token = @user.jwt_auth_token
        # ::NodeManager.send_data('send_sso_data', {data: @session,status: "Success" })
        # respond_with @session, location: root_path
        # render json: {status: "Success"}
        if valid_url?(session[:url])
          redirect_to session[:url] + "/ssologin?token=" + token
        end
      else
        reset_session
        if valid_url?(session[:url])
          redirect_to session[:url] + "/ssologin?token=" + token
        end
      end
    rescue CloudStreet::UnprocessableEntity => error
      message = JSON.parse(error.response.body)['message']
      #errors.add(:session, message)
      reset_session
      if valid_url?(session[:url])
        redirect_to session[:url] + "/ssologin?token=" + token
      end
    end

    def sso
      settings = AccountSamlSetting.get_saml_settings(get_url_base(true))
      if settings.nil?
        # render :action => :no_settings
        return false
      end
      request = OneLogin::RubySaml::Authrequest.new
      # redirect_to(request.create(settings))
      render json: {path: request.create(settings)}, status: :ok
      # ::NodeManager.send_data('sso_url', { sso_url: request.create(settings),status: "success"})
    end

    def metadata
      settings = AccountSamlSetting.get_saml_settings(get_url_base)
      meta = OneLogin::RubySaml::Metadata.new
      render :xml => meta.generate(settings, true)
    end

    # Trigger SP and IdP initiated Logout requests
    def logout
      # If we're given a logout request, handle it in the IdP logout initiated method
      if params[:SAMLRequest]
        return idp_logout_request
      # We've been given a response back from the IdP
      elsif params[:SAMLResponse]
        return process_logout_response
      elsif params[:slo]
        return sp_logout_request
      else
        reset_session
        # redirect_to login_path
        render json: {status: "Success"}
      end
    end

      # Create an SP initiated SLO
    def sp_logout_request
      # LogoutRequest accepts plain browser requests w/o paramters
      settings = AccountSamlSetting.get_saml_settings(get_url_base)

      if settings.idp_slo_target_url.nil?
        logger.info "SLO IdP Endpoint not found in settings, executing then a normal logout'"
        reset_session
      else

        # Since we created a new SAML request, save the transaction_id
        # to compare it with the response we get back
        logout_request = OneLogin::RubySaml::Logoutrequest.new()
        session[:transaction_id] = logout_request.uuid
        logger.info "New SP SLO for User ID: '#{session[:nameid]}', Transaction ID: '#{session[:transaction_id]}'"

        if settings.name_identifier_value.nil?
          settings.name_identifier_value = session[:nameid]
        end

        relayState = url_for controller: 'saml', action: 'index'
        # redirect_to(logout_request.create(settings, :RelayState => relayState))
         render json: {path: logout_request.create(settings, :RelayState => relayState)}, status: :ok
      end
    end

    # After sending an SP initiated LogoutRequest to the IdP, we need to accept
    # the LogoutResponse, verify it, then actually delete our session.
    def process_logout_response
      settings = AccountSamlSetting.get_saml_settings(get_url_base)
      request_id = session[:transaction_id]
      logout_response = OneLogin::RubySaml::Logoutresponse.new(params[:SAMLResponse], settings, :matches_request_id => request_id, :get_params => params)
      logger.info "LogoutResponse is: #{logout_response.response.to_s}"

      # Validate the SAML Logout Response
      if not logout_response.validate
        error_msg = "The SAML Logout Response is invalid.  Errors: #{logout_response.errors}"
        logger.error error_msg
        # render :inline => error_msg
        render json: {inline: error_msg}, status: :ok
      else
        # Actually log out this session
        if logout_response.success?
          logger.info "Delete session for '#{session[:nameid]}'"
          reset_session
        end
      end
    end

    # Method to handle IdP initiated logouts
    def idp_logout_request
      settings = AccountSamlSetting.get_saml_settings(get_url_base)
      logout_request = OneLogin::RubySaml::SloLogoutrequest.new(params[:SAMLRequest], :settings => settings)
      if not logout_request.is_valid?
        error_msg = "IdP initiated LogoutRequest was not valid!. Errors: #{logout_request.errors}"
        logger.error error_msg
        render :inline => error_msg
      end
      logger.info "IdP initiated Logout for #{logout_request.nameid}"

      # Actually log out this session
      reset_session

      logout_response = OneLogin::RubySaml::SloLogoutresponse.new.create(settings, logout_request.id, nil, :RelayState => params[:RelayState])
      # redirect_to logout_response
      render json: {path: logout_response}, status: :ok
    end

    def get_url_base(set=false)
      if set
        # port = params[:port].present? && params[:port].eql?("80") ? "" : ":#{params[:port]}"
        session[:url] = params[:protocol] + "//" + params[:host] 
      end
      return session[:url]
    end

    def sso_configs
      result = SsoConfigService.get_sso_configs
      if result
        render json: result, status: :ok
      else
        render json: { message: "Something weng wrong." }, status: 422
      end
    end

    def update
      result = SsoConfigService.create_or_update_settings(sso_params)
      if result
        render json: result, status: :ok
      else
        render json: { message: "Something weng wrong." }, status: 422
      end
    end

    def saml_disable
      status = SsoConfig.first ? SsoConfig.first.disable : false
      render json: {status: status}
    end

    private
    def sso_params
      params.permit(:idp_sso_target_url, :idp_slo_target_url, :certificate, :disable, :account_id, :idp_entity_id)
    end

    def valid_url?(url)
      uri = URI.parse(url)
      host = uri.host
      parameters = host.split('.')
      uri.is_a?(URI::HTTP) && !host.nil? && parameters.length.eql?(3)
    rescue URI::InvalidURIError
      false
    end
  end
end
