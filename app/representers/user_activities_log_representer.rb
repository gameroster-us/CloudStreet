module UserActivitiesLogRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  
  collection(
    :user_activity_log,
    class: UserActivityLog,
    extend: UserActivityLogRepresenter,
    embedded: true)

  def user_activity_log
    collect
  end
end