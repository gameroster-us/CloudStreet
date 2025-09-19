class CloudStreetExceptions::InvalidParameterCombination < CloudStreetException
  attr_reader :error_obj

  def initialize(error_obj)
    @error_obj = error_obj
  end
end
