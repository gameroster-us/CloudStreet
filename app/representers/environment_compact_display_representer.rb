module EnvironmentCompactDisplayRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :id
  property :name
  property :application_id
  property :default_adapter_id, as: :adapter_id

end
