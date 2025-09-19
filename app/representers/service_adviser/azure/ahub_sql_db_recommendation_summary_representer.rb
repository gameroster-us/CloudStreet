module ServiceAdviser::Azure::AhubSQLDBRecommendationSummaryRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  collection(
    :ahub_sql_db_recommendation,
    class: Azure::Recommendation,
    extend: SQLDBRecommendationRepresenter,
    embedded: true
  )

  property :meta_data, getter: ->(args) { args[:options][:total_records][:meta_data] }

  def ahub_sql_db_recommendation
    collect
  end
end
