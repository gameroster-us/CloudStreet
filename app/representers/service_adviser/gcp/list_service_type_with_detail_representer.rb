# frozen_string_literal: true

# gcp service type with detail representer
module ServiceAdviser::GCP::ListServiceTypeWithDetailRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  property :total_service_count
  collection(:services, extend: ::ServiceAdviser::GCP::ServiceRepresenter)

  def total_service_count
    self[:total_service_count]
  end

  def services
    self[:services]
  end
end
