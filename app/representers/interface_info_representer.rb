module InterfaceInfoRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :name
  property :type
  property :limit
  property :max_connections

  collection(
    :properties,
    class: Property,
    extend: PropertyRepresenter)
end
