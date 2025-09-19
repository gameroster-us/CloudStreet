module MetricsRepresenter
include Roar::JSON
include Roar::Hypermedia
include Roar::JSON::HAL

  collection(
    :metrics,
    extend: MetricRepresenter,
    embedded: true)

  def metrics
    collect
  end
end
