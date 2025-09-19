module AdapterDirectoryRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :adapter,
    class: AdapterDirectoryInfo,
    extend: AdapterDirectoryInfoRepresenter,
    embedded: true)

  link :self do
    directory_adapters_path
  end

  def adapter
    collect
  end
end
