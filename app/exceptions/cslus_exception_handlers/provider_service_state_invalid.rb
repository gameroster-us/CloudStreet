class CloudStreetExceptionHandlers::ProviderServiceStateInvalid < CloudStreetExceptionHandler
  DEFAULT_ERROR_CODE = 103
  DEFAULT_HTTP_CODE  = 409
  DEFAULT_ERROR_MSG  = 'provider service is in invalid state'

  def initialize(exception)
    super
    @provider_service = exception.provider_service
    @event = exception.event
  end

  def get_data
    {
      id: error_obj.id,
      name: error_obj.name,
      type: error_obj.type,
      state: error_obj.state,
      provider_service: {
        state: provider_service.state
      },
      event: event
    }
  end
end
