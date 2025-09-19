require "azure/service"
class Azure::Network::RouteTable < ApplicationRecord
  include Azure::Service
  self.table_name = "azure_route_tables"

  ASSOCIATED_SERVICE_TYPES = %w(Azure::Network::Vnet)

  REUSABLE = true
  AZURE_RESOURCE_TYPE = "Microsoft.Network/routeTables"
  def init_associations(association_hash)
  end

  class << self
    def get_associated_services_for_tag_filter(service_id, association_hash, associated_service_ids=[])
      subnets = []
      association_hash["Azure::Network::Subnet"].each do |a_service_id, associations|
        associations.each do |service_type, ids|
          if service_type == "Azure::Network::RouteTable" && ids.include?(service_id)
            subnets << a_service_id
            associated_service_ids.concat([a_service_id])
            associated_service_ids.concat(Azure::Network::Subnet.get_associated_services_for_tag_filter(a_service_id, association_hash))
          end
        end
      end
      if subnets.present?
        association_hash["Azure::Compute::VirtualMachine"].try(:each) do |a_service_id, associations|
          associations.each do |service_type, ids|
            if (service_type == "Azure::Network::Subnet") && (ids & subnets).present?
              associated_service_ids.concat([a_service_id])
              associated_service_ids.concat(Azure::Compute::VirtualMachine.get_associated_services_for_tag_filter(a_service_id, association_hash))
            end
          end
        end
      end
      associated_service_ids
    end
  end
end
