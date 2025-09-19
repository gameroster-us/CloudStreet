module AdaptersBasicInfoRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :total_records

  collection(
    :adapter,
    class: AdapterBasicInfo,
    extend: AdapterBasicInfoRepresenter,
    embedded: true)

  collection(
    :selected_adapter,
    class: AdapterBasicInfo,
    extend: AdapterBasicInfoRepresenter,
    embedded: true)

  def adapter
    self[:adapters]
  end

  def selected_adapter
    self[:selected_adapters]
  end

  def total_records
    self[:total_records]
  end
end
