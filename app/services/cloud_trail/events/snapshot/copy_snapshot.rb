module CloudTrail::Events::Snapshot::CopySnapshot
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "******* Inside CopySnapshot *******"
    attributes_for_snapshots(get_event_attributes_for_vol_snap)
    CTLog.info "Copied Volume Snapshot"
  end
end
