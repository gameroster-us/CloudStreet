module GlobalAdmin::MiraEndpointsRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :total_records

  collection(
    :mira_endpoints,
    class: MiraEndpoint,
    extend: GlobalAdmin::MiraEndpointRepresenter,
    embedded: true
  )

  def mira_endpoints
    self[:mira_endpoints].collect
  end

  def total_records
    self[:total_records]
  end

end