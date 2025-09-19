class SecurityScanStorageStatus < Status
  def self.success(security_scan)
    new(:success, security_scan)
  end

  def self.validation_error(security_scan)
    new(:validation_error, security_scan)
  end

  def initialize(status, security_scan=nil, error=nil)
    @status = status
    @security_scan    = security_scan
    @error  = error
  end

  def on_success
    yield(@security_scan) if @status == :success
  end

  def on_validation_error
    yield(@security_scan) if @status == :validation_error
  end
end
