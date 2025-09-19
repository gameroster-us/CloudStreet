module AccountRegionRepresenter
include Roar::JSON
include Roar::Hypermedia

  property :enabled
  property :region_id
  property :region_name
end
