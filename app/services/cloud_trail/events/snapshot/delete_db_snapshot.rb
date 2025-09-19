module CloudTrail::Events::Snapshot::DeleteDBSnapshot
  include CloudTrail::Utils::EventConfigHelper

  def process
    CTLog.info "**** Inside DeleteRDSSnapshot ****"
    attributes_for_delete_snap(get_event_attributes_for_rds_snap)
    CTLog.info "Deleted RDS Snapshot"
  end
end
