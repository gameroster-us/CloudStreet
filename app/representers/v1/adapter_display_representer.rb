module V1
  module AdapterDisplayRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :id
    property :name

  end
end
