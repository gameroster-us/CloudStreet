class CloudStreetExceptionHandler
  attr_reader :exception, :error_obj

  DEFAULT_ERROR_CODE = 500
  DEFAULT_HTTP_CODE  = 500
  DEFAULT_ERROR_MSG  = 'internal server error'
  DEFAULT_ERROR_DATA = {}

  def initialize(exception)
    @exception = exception
    @error_obj = @exception.error_obj
  end

  def handle_exception
    handler = find_handler
    handler.handle
  end

  def find_handler
    class_name = exception.class.to_s
    # CloudStreetExceptions::InvalidStates::Adapter to  CloudStreetExceptionHandlers::InvalidState
    class_name.gsub('CloudStreetExceptions', 'CloudStreetExceptionHandlers').constantize.new(exception)
  end

  def handle
    return_value
  end

  def return_value
    {
      http_code: get_http_code,
      error_code: get_error_code,
      error_msg: get_error_msg,
      data: get_data
    }
  end

  def get_error_code
    self.class::DEFAULT_ERROR_CODE
  end

  def get_error_msg
    self.class::DEFAULT_ERROR_MSG
  end

  def get_data
    self.class::DEFAULT_ERROR_DATA
  end

  def get_http_code
    self.class::DEFAULT_HTTP_CODE
  end
end
