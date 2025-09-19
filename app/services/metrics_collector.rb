class MetricsCollector < CloudStreetService
  def self.collect(collector=ServiceMonitorableCloudwatch, &block)

    services = Service.where("type IN (?) AND state = 'running'", *collector.service_type)

    services.each { |service| collector.delay(queue: :monitoring).collect(service) }
  end
end
