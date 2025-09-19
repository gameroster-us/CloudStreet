class UserStatus < Status
  def self.no_invite_token_found
    new(:no_invite_token_found)
  end

  def self.requires_confirmation
    new(:requires_confirmation)
  end

  def self.deactivated
    new(:deactivated)
  end

  def self.no_confirmation_token_found
    new(:no_confirmation_token_found)
  end

  def self.validation_failed(errors)
    new(:validation_failed, errors)
  end

  def self.awaiting_confirmation
    new(:awaiting_confirmation)
  end

  def on_no_invite_token_found
    yield if @status == :no_invite_token_found
  end

  def on_requires_confirmation
    yield if @status == :requires_confirmation
  end

  def on_deactivated
    yield if @status == :deactivated
  end

  def on_no_confirmation_token_found
    yield if @status == :no_confirmation_token_found
  end

  def on_validation_failed
    yield(@resources) if @status == :validation_failed
  end

  def on_awaiting_confirmation
    yield if @status == :awaiting_confirmation
  end

end
