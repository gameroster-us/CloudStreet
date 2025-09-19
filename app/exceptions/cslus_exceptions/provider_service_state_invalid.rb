class CloudStreetExceptions::ProviderServiceStateInvalid < CloudStreetException
  attr_reader :error_obj, :event, :provider_service

  def initialize(error_obj, provider_service:, event:)
    @error_obj = error_obj
    @provider_service = provider_service
    @event = event
  end
end
