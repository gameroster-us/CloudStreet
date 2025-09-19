module GCP
  module AccountMultiRegionRepresenter
    include Roar::JSON
    include Roar::Hypermedia

    property :multi_regional_id
    property :multi_regional_name
    property :multi_regional_code
    property :enabled
  end
end