module ServiceAdviser::Azure::AhubRecommendation::ElasticPoolRepresenter
  include Roar::JSON
  include Roar::Hypermedia

  collection(
    :ahub_sql_elastic_pool_recommendation,
    class: Azure::Recommendation,
    extend: ServiceAdviser::Azure::AhubRecommendationRepresenter,
    embedded: true
  )

  property :meta_data, getter: ->(args) { args[:options][:total_records][:meta_data] }

  def ahub_sql_elastic_pool_recommendation
    collect
  end
end
