class Api::V2::Private::UsersController < Api::V2::Private::BaseController
  before_action :check_validation
  respond_to :json

  def create
    UserSignuperer.signup(user_params) do |result|
      result.on_success               { |user| respond_with user, status: 200, represent_with: UsersRepresenter, location: users_url }
      result.on_validation_failed     { |errors| respond_with CloudStreetError.new(:validation_error, errors, "Validation errors"), status: 422, represent_with: CloudStreetErrorRepresenter, location: nil }
      result.on_no_invite_token_found { respond_with CloudStreetError.new(:invite_token_not_found), status: 422, represent_with: CloudStreetErrorRepresenter, location: nil }
      result.on_requires_confirmation { render json: {message: 'Sent confirmation mail to given email address'}, status: 200 }
      result.on_awaiting_confirmation { respond_with CloudStreetError.new(:awaiting_confirmation), status: 422, represent_with: CloudStreetErrorRepresenter , location: nil}
      result.on_error                 { render body: nil, status: 500 }
    end
  end

private
  def user_params
    params.merge!(organisation_attributes: {})
    permit_perms = params.permit(:subdomain,:username, :host_, :unconfirmed_email, :password, :password_confirmation, :invite_token, :name, :signup_as, :registration_token, organisation_attributes: {} , account_attributes: [:name])
    permit_perms.to_h.tap{|p|
      p[:host_]=Settings.host if p[:host_].blank?
      p
    }
  end

  def check_validation
    return render json: { message: "Username must be at least 3 characters long" }, status: 422 unless params[:username].present? && params[:username].to_s.length >= 3

    return render json: { message: "Please enter valid email." }, status: 422 unless params[:unconfirmed_email].present? && params[:unconfirmed_email].match(/\A\S+@.+\.\S+\z/)

    return render json: { message: "Use 8 to 40 characters with a mix of uppercase and lowercase letters, numbers and symbols." }, status: 422 unless params[:password].present? && params[:password].match(/[a-z]+/,) && params[:password].match(/[A-Z]+/,) && params[:password].match(/\d+/,) && params[:password].match(/[^A-Za-z0-9]+/) && params[:password].length >= 8 && params[:password].length <= 40
  end
end
