module ServiceEventRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :revision
  property :username
  property :component_name
  property :id
  property :type
  property :event
  property :event_on
  property :updated_at, getter: lambda { |*| updated_at.strftime CommonConstants::DEFAULT_TIME_FORMATE }
  property :user, extend: UserRevisionRepresenter
  property :service, extend: ServiceRevisionRepresenter
  
  # property :event
  # property :start_date
  # property :end_date
  # property :cost
  # property :duration

  # link :self do
  #   events_services_path(represented)
  # end
  
  def component_name
    service.name
  end 

  def username 
    user.username
  end

  def event
    return represented.event_name if represented.try(:event_name).present?
    arr = type.split('::')
    arr[arr.length-1]
  end  

  def event_on
    arr = type.split('::')
    arr[arr.length-2]
  end 
end
