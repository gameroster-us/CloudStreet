module EnvironmentChangesRepresenter
include Roar::JSON
include Roar::Hypermedia
  include ServiceRepresenterName

  property :id
  property :name

  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
end