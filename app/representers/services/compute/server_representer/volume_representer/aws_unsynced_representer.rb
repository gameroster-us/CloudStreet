module Services
  module Compute
    module ServerRepresenter
      module VolumeRepresenter
          module AWSUnsyncedRepresenter
            include Roar::JSON
            include Roar::Hypermedia
            include ServicesRepresenter
            include ServerRepresenter
            include VolumeRepresenter

            # attributes from data
            property :id
            property :iops
            property :size
            property :volume_type
            property :device
            property :status
            property :root_device
            property :attach_status
            property :adapter, extend: AdapterDisplayRepresenter
            property :region, extend: RegionInfoRepresenter
            property :tags
            property :service_tags

            # # attributes from provider_data
            property :get_availability_zone_name, as: :availability_zone
        end
      end
    end
  end
end
