module TemplateEventRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :type
  property :time
  property :user
  property :template, extend: TemplateRepresenter

  # link :self do
  #   event_path(id)
  # end
end
