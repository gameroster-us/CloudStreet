# frozen_string_literal: true

module V2::AccountRegionInfoRepresenter

  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL

  property :enabled
  property :region_id
  property :region_name
  property :adapter_type
  property :code
  property :adapter_id

end
