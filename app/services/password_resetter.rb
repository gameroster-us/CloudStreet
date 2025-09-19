class PasswordResetter < CloudStreetService
  def self.request(params, &block)
    PasswordResetWorker.perform_async(params.to_h)
    status UserStatus, :success, nil, &block
  end

  def self.reset(params, &block)
    @reset_password = ResetPassword.new(params)
    status, message = @reset_password.reset
    if status
      status UserStatus, :success, nil, &block
    else
      status UserStatus, :validation_failed, message, &block
    end
  end
end