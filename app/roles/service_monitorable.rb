class ServiceMonitorable
  attr_reader :service

  delegate :id, to: :service
  delegate :type, to: :service
  delegate :state, to: :service

  def initialize(service)
    @service = service
  end

  def throughput
    Random.new.rand(500)
  end

  def response_time
    Random.new.rand(500)
  end

  def error_rate
    Random.new.rand(5)
  end

  def collect
    ServiceCloudwatchable.new(service).get_metrics
  end
end
