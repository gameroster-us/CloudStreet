module EnvironmentsDisplayRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :total_records, getter: lambda { |args| args[:options][:total_records]}

  collection(
    :environment,
    class: Environment,
    extend: EnvironmentDisplayRepresenter,
    embedded: true)

  def environment
    collect
  end
end
