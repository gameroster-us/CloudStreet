module EnvironmentSnapshotsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL
  collection(
    :snapshots,
    class: Snapshot,
    extend: Snapshots::AWSRepresenter)

  def snapshots
    self
  end
end
