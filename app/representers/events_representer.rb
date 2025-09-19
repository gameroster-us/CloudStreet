module EventsRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :event,
    class: Event,
    extend: lambda do |event, *|
      if event.class.name.include? "Environment"
        EnvironmentEventRepresenter
      elsif event.class.name.include? "Template"
        TemplateEventRepresenter
      elsif event.class.name.include? "Adapter"
        AdapterEventRepresenter
      elsif event.class.name.include? "Service"
        ServiceEventRepresenter
      else
        EventRepresenter
      end
    end,
    embedded: true)

  def event
    collect
  end

  link :self do
    events_path
  end

  link :services do
    { href: "/events/services{?environment_id,service_id,start_date,end_date}", templated: "true" }
  end

  # def service_events
  #   collect
  # end
end
