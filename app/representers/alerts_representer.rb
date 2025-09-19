module AlertsRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :alerts,
    class: Alert,
    extend: AlertRepresenter,
    embedded: true)

  def alerts
    collect
  end
end
