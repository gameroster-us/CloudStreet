module Private
  class ResetPasswordsController < BaseController
    def create
      PasswordResetter.request(create_params) do |result|
        result.on_success { render json: {}, status: 200 }
        result.on_error { render json: :nothing, status: 500 }
      end
    end

    def update
      PasswordResetter.reset(update_params) do |result|
        result.on_success { render json: {}, status: 200 }
        result.on_validation_failed { |error| render json: {message: error}, status: 422 }
        result.on_error   { render json: :nothing, status: 500 }
      end
    end

  private

    def cloudstreet_errors_url; end

    def create_params
      params.permit(:email, :host)
    end

    def update_params
      params.permit(:token, :password, :password_confirmation)
    end
  end
end
