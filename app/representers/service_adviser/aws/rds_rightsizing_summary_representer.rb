# RDS Right Sizing Represnter
module ServiceAdviser::AWS::RdsRightsizingSummaryRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  collection(
    :rds_right_sizings,
    class: RdsRightSizing,
    extend: RdsRightsizingRepresenter,
    embedded: true
  )

  property :meta_data, getter: ->(args) { args[:options][:total_records][:meta_data] }

  def rds_right_sizings
    collect
  end
end
