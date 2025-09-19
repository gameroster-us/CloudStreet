module Synchronizer
  module AWS
    module Services
      module RouteTableRepresenter
include Roar::JSON
include Roar::Hypermedia
        #todo  ability to distinguish where the id correspond to route table or service table
        property :id
        property :synced_to
        property :region
        property :adapter
        property :name
        property :provider_id
        property :vpc_id
        property :synchronized

        property :associations
        property :routes
        property :tags
        property :service_tags

        def tags
          provider_data["tags"]
        end
      end
    end
  end
end