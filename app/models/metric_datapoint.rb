class MetricDatapoint < Array
  attr_accessor :datapoint

  def initialize(datapoint)
    @datapoint = datapoint
  end
end
