module EnvironmentEventRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :revision
  property :username
  property :component_name
  property :id
  property :type
  property :time
  property :event
  property :event_on
  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :environment, extend: EnvironmentRevisionRepresenter
  property :user, extend: UserRevisionRepresenter
  
  # link :self do
  #   event_path(id)
  # end
  def component_name
    environment.name
  end

  def username
    user.username
  end

  def event
    arr = type.split('::')
    arr[arr.length-1]
  end

  def event_on
    arr = type.split('::')
    arr[arr.length-2]
  end
end
