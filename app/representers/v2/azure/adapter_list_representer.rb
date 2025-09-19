module V2::Azure::AdapterListRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  collection(
    :adapter,
    class: Adapter,
    extend: V2::Azure::AdapterListObjectRepresenter)


  def adapter
    self[:adapters]
  end

end