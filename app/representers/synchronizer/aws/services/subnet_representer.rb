module Synchronizer
  module AWS
    module Services
      module SubnetRepresenter
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
        
        property :cidr_block
        property :available_ip_address_count
        property :availability_zone
        property :tags
        property :service_tags

        def tags
          self.parsed_provider_data["tag_set"]
        end

        def available_ip_address_count
          self.parsed_provider_data["available_ip_address_count"] 
        end

        def availability_zone
          self.parsed_provider_data["availability_zone"] || fetch_remote_services(Protocols::AvailabilityZone).first.data["code"]
        end

        def cidr_block
          self.parsed_provider_data["cidr_block"]
        end
      end
    end
  end
end