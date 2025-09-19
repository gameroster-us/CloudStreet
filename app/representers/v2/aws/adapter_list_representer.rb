module V2::AWS::AdapterListRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  collection(
    :adapter,
    class: Adapter,
    extend: V2::AWS::AdapterListObjectRepresenter)


  def adapter
    self[:adapters]
  end

end