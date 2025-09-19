module V2::ReportProfileListRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  collection(
    :report_profiles,
    class: ReportProfile,
    extend: V2::ReportProfileListObjectRepresenter
  )

  def report_profiles
    self
  end

end
