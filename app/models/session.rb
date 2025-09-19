class Session
  attr_reader :user, :host

  def initialize(user, host='nil')
    @user = user
    @host = host
  end

  def username
    user.username
  end

  def password
    user.password
  end

  def authentication_token
    user.authentication_token
  end

  def user_id
    user.id
  end

  def account_id
    # user.account.id
  end

  def oraganisation_id
    user.oraganisation_id
  end

  # def user
  #   if username.present? && password.present?
  #     @user ||= User.find_by_username(username).try(:authenticate, password)
  #     @user
  #   end
  # end
end
