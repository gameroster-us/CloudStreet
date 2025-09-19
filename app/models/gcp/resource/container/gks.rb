class GCP::Resource::Container::Gks < GCP::Resource::Container

  include Synchronizers::GCP
  include GCP::Resource::CostCalculator
  
  store_accessor :data, :endpoint, :version, :creation_time, :node_count, :status, :locations, :zone, :location_type, :mode

  scope :filter_by_location_type, -> (location_type) { where("data->>'location_type' = ?", location_type) }

  ACTIVE_STATUS = %i[provisioning reconciling running stopping error degraded]

  scope :active, -> { where(state: ACTIVE_STATUS) }
end