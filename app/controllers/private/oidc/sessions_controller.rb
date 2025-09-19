class Private::OIDC::SessionsController < Private::BaseController

  include Private::OIDC::Concerns::RequestValidator

  before_action :require_response_type_code
  before_action :require_client
  before_action :set_parent_org, only: [:create ]
  # after_action :set_header, only: [:create ]

  def create
    # CSLogger.info "params====#{params}"
    SessionCreator.create(params[:username], params[:password], params[:host], nil, params[:mfa_code]) do |result|
      result.on_success  do |session|
        @user = session.user
        @organisation = @parent_organisation
        # if @user.mfa_enabled && params[:mfa_code].blank?
        #   render json: { mfa_enabled: true }
        #   return nil
        # end
        # adapters_group_status = UserSearcher.get_adapters_group_status(current_account, current_tenant)
        # respond_with_user_and @user, represent_with: UserRepresenter, adapters_status: UserSearcher.get_adapters_status(current_account, current_tenant, user: @user), adapters_group_status: adapters_group_status, location: nil
        CSLogger.info "resp executing from OIDC session------"

        jwt_token = @user.jwt_auth_token(@organisation, cookies["user_mfa_credentials"])

        cookie_options = {
          value: jwt_token,
          httponly: false,
          secure: false,
          expires: 5.minutes.from_now,
          path: '/'
        }

        response.headers['Set-Cookie'] = "jwttoken=#{jwt_token}; expires=#{cookie_options[:expires].utc.strftime('%a, %d %b %Y %H:%M:%S GMT')}; path=#{cookie_options[:path]};SameSite=None;"
        # response.headers['Set-Cookie'] = "jwtToken=#{cookie_options[:value]}; expires=#{cookie_options[:expires].utc.strftime('%a, %d %b %Y %H:%M:%S GMT')}; path=#{cookie_options[:path]}; secure=#{cookie_options[:secure]}"
        # head :temporary_redirect, location: redirect_url
        # head :not_found, location: redirect_url, status: :temporary_redirect
        # render redirect_url, status: :temporary_redirect

        redirect_url = "#{params[:host]}/api/oidc/authorizations?jwttoken=#{jwt_token}&" + request.query_parameters.to_query

        render json: { redirect_url: redirect_url }
      end
      # result.on_disabled { |session| render json: { message: I18n.t('errors.auth.account_disabled') }, status: 422 }
      # result.on_error    { |message| render json: { message:  message}, status: 422 }
      # result.on_requires_confirmation { |session| render json: { message: I18n.t('errors.auth.email_not_yet_confirmed') }, status: 422 }
      # result.on_deactivated { |message| render json: { message: I18n.t('errors.auth.organisation_deactivated') }, status: 422 }
    end
  end

  private

  def set_parent_org
    @parent_organisation = Organisation.find_by_host(params[:host])
  end

  def set_header
    response.headers['authorization'] = nil unless @user
    if @user && @organisation
      # when user mfa enable and mfa code not submited this happen first time when user login with username and password
      if @user.mfa_enabled && params[:mfa_code].blank?
        response.headers['authorization'] = nil
      else
        response.headers['authorization'] = @user.jwt_auth_token(@organisation, cookies["user_mfa_credentials"])
      end
    end
  end

  def blacklist_token(auth_token)
    decoded_auth_token = AuthToken.decode(auth_token)
    # Our session expiry time is one hour, after that in some cases for decoding the auth_token it is taking expired auth token, this results in decoded_auth_token nil for handling that added if statement
    if decoded_auth_token.present?
      expiry_time = Time.at(decoded_auth_token["exp"]) + 2.minutes
      expiry_in =  (expiry_time - Time.now).ceil
      $redis.set("jwt_tokens:#{auth_token}", decoded_auth_token["user_id"], ex: expiry_in)
    end
  end

end
