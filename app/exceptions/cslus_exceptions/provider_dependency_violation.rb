class CloudStreetExceptions::ProviderDependencyViolation < CloudStreetException
  attr_reader :error_obj, :event, :dependent_service

  def initialize(error_obj, dependent_service:, event:)
    @error_obj = error_obj
    @dependent_service = dependent_service
    @event = event
  end  
  
end