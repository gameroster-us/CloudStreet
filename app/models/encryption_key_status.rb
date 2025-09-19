class EncryptionKeyStatus < Status
  def self.success(encryption_key)
    new(:success, encryption_key)
  end

  def self.validation_error(encryption_key)
    new(:validation_error, encryption_key)
  end

  def initialize(status, encryption_key=nil, error=nil)
    @status = status
    @encryption_key    = encryption_key
    @error  = error
  end

  def on_success
    yield(@encryption_key) if @status == :success
  end

  def on_validation_error
    yield(@encryption_key) if @status == :validation_error
  end
end
