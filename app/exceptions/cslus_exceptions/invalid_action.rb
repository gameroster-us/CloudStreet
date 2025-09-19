class CloudStreetExceptions::InvalidAction < CloudStreetException
  attr_reader :error_obj, :action

  def initialize(error_obj, action)
    @error_obj = error_obj
    @action    = action
  end
end
