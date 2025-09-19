module SoeScripts::RunCommandGroupsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :total_records, getter: lambda { |args| args[:options][:total_records]}, unless: lambda { |args| args[:options][:mininfo].eql?(true) }

  collection(
    :soe_groups,
    class: SoeScripts::Group,
    extend: SoeScripts::RunCommandGroupRepresenter,
    embedded: false)

  def soe_groups
    self
  end
end
