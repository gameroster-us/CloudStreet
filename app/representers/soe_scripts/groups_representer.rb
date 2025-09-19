module SoeScripts::GroupsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  property :total_records, getter: lambda { |args| args[:options][:total_records]}, unless: lambda { |args| args[:options][:mininfo].eql?(true) }

  collection(
    :soe_groups,
    class: SoeScripts::Group,
    extend: SoeScripts::GroupRepresenter,
    embedded: false)

  def soe_groups
    self
  end
end
