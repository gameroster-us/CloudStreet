module RegionsRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :region,
    class: RegionInfo,
    extend: RegionInfoRepresenter,
    embedded: true)

  link :self do
    regions_path
  end

  def region
    collect
  end
end
