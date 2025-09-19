class CloudStreetExceptionHandlers::InvalidAction < CloudStreetExceptionHandler
  attr_reader :action

  DEFAULT_ERROR_CODE = 104
  DEFAULT_HTTP_CODE  = 409
  DEFAULT_ERROR_MSG  = 'invalid action'

  def initialize(exception)
    super
    @action = exception.action
  end

  def get_data
    {
      id: error_obj.id, 
      name: error_obj.name,
      type: error_obj.type,
      action: action
    }
  end
end
