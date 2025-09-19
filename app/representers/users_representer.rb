module UsersRepresenter
include Roar::JSON
include Roar::Hypermedia
include Roar::JSON::HAL

  property :total_records, getter: lambda { |args| args[:options][:total_records]}

  collection(
    :users,
    class: User,
    extend: UserRepresenter,
    embedded: true)

  def users
    collect
  end

  link :self do
    users_path
  end
end
