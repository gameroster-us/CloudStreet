class AWSSdkWrappers::Response
  attr_accessor :success, :data, :errors
  
  def initialize
    @success = nil
    @data = nil
    @error = nil
  end

  def success!(result)
    @success = true
    @data = result
  end

  def error!(error)
    @success = false
    @errors = {
      message: error.message,
      type: error.class
    }
  end
end
