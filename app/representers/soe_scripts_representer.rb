module SoeScriptsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  property :total_records, getter: lambda { |args| args[:options][:total_records]}

  collection(
    :soe_scripts,
    class: SoeScript,
    extend: SoeScriptRepresenter,
    embedded: false)

  def soe_scripts
    self
  end
end
