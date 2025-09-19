# frozen_string_literal: true

module VmWare

  module EventRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :id
    property :name
    property :inventory, extend: ServiceAdviser::VmWare::ServiceRepresenter

    property :status
    property :forceful_apply
    property :count
    property :size
    property :cores_per_socket
    property :error

    def inventory
      vw_inventory
    end
  end

  module EventsRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    collection(:services, extend: EventRepresenter, embedded: false)

    def services
      self
    end
  end
end



VmWare::EventsRepresenter.prepare(VwEvent.limit(2)).to_json
