module EnvironmentTagsRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :environment_tags,
    class: EnvironmentTag,
    extend: EnvironmentTagRepresenter,
    embedded: false)

  def environment_tags
    collect
  end
end
