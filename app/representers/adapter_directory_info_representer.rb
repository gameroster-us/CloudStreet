module AdapterDirectoryInfoRepresenter
include Roar::JSON
include Roar::Hypermedia
  property :id
  property :name
  property :type
  property :provider_name

  collection(
    :properties,
    class: Property,
    extend: PropertyRepresenter)

  collection(
      :regions,
      class: RegionInfo,
      extend: RegionInfoRepresenter,
      embedded: true)
  # link :self do
  #   directory_adapters_path
  # end
end
