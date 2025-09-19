module SnapshotsRepresenter
include Roar::JSON
include Roar::Hypermedia
include Roar::JSON::HAL
  collection(
    :snapshot,
    class: Snapshot,
    extend: SnapshotRepresenter,
    embedded: true)

  link :self do
    { href: "#{snapshots_path}", templated: "true" }
  end

  def snapshot
    collect
  end
end
