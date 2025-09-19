require "azure/service"
class Azure::Network::Subnet < ApplicationRecord
  include Azure::Service
  include Behaviors::TemplateDeployable::Azure::Network::Subnet
  self.table_name = "azure_subnets"

  ASSOCIATED_SERVICE_TYPES = %w(Azure::Network::Vnet Azure::Network::RouteTable Azure::Network::SecurityGroup)

  REUSABLE = true
  AZURE_RESOURCE_TYPE = "Microsoft.Network/subnet"

  def init_associations(association_hash)
    begin
      associated_services = []
      vnet_name = self.CS_service.associated_services.find_by_service_type("Azure::Network::Vnet").name
      vnets_provider_id = vnet_provider_id(vnet_name)
      vnet_metadata = association_hash[vnets_provider_id]["info"]
      association_hash[self.provider_id]["associations"]["Azure::Network::Vnet"] << vnets_provider_id
      subnet_metadata = {"id" => self.CS_service_id, "provider_id" => self.provider_id}
      if self.route_table.present?
        rt_metadata = association_hash[self.route_table]["info"]
        associated_services << AssociatedService.process_associations(subnet_metadata, rt_metadata, association_hash)
        associated_services << AssociatedService.process_associations(rt_metadata, vnet_metadata, association_hash)
      end
      if self.security_group.present?
        sg_metadata = association_hash[self.security_group]["info"]
        associated_services << AssociatedService.process_associations(subnet_metadata, sg_metadata, association_hash)
        associated_services << AssociatedService.process_associations(sg_metadata, vnet_metadata, association_hash)
      end
    rescue Exception => e
      CSLogger.error "Error occured in building associations for service => Name: #{self.name} Type: #{self.class} Provider ID: #{self.provider_id} , #{e.class} #{e.message} #{e.backtrace}"
    ensure
      return associated_services
    end
  end

  # returns associated_service's provider_id
  def is_associated_with(with_service_type, associated_service_id_map)
    case with_service_type
    when "Azure::Network::Vnet"
      associated_service_id_map.keys & depends_on
    end
  end

  def self.set_metadata
    [
      {
        "name" => "address_prefix",
        "title" => "Address Range",
        "value" => "192.168.1.0/24"
      }
    ]
  end

  def vnet_provider_id(vnet_name)
    "/subscriptions/#{Parsers::Azure::ServiceNameParser.parse_subscription_id(self.provider_id)}/resourceGroups/#{Parsers::Azure::ServiceNameParser.parse_resource_group_name(self.provider_id)}/providers/Microsoft.Network/virtualNetworks/#{vnet_name}"
  end

  def form_provider_id(provider_subscription_id, resource_group_name, parent_service_name="")
    "/subscriptions/#{provider_subscription_id}/resourceGroups/#{resource_group_name}/providers/Microsoft.Network/virtualNetworks/subnets/#{parent_service_name}/#{self.name}"
  end

  # def set_association_based_attributes(associated_services, params={})
  #   associated_services.each do |associated_service|
  #     case associated_service["service_type"]
  #     when "Azure::Network::SecurityGroup"
  #       self.security_group = "/subscriptions/#{params['provider_subscription_id']}/resourceGroups/#{params['resource_group_name']}/providers/#{::Azure::Network::SecurityGroup::AZURE_RESOURCE_TYPE}/#{associated_service['name']}"
  #       CSLogger.info "self.security_group---- #{self.security_group}"
  #     when "Azure::Network::RouteTable"
  #       self.route_table = "/subscriptions/#{params['provider_subscription_id']}/resourceGroups/#{params['resource_group_name']}/providers/#{::Azure::Network::RouteTable::AZURE_RESOURCE_TYPE}/#{associated_service['name']}"
  #     end
  #   end
  # end

  class << self
    def get_associated_services_for_tag_filter(service_id, association_hash, associated_service_ids=[])
      service_associations = association_hash["#{self}"][service_id]
      associated_service_ids.concat(service_associations.values.flatten)
    end

    def parse_subnet_name(subnet_id)
      if subnet_id.include?("/providers/Microsoft.Network/virtualNetworks/subnets/")
        subnet_name = Parsers::Azure::ServiceNameParser.parse_new_subnet_name(subnet_id) rescue ""
      else
        subnet_name = Parsers::Azure::ServiceNameParser.parse_subnet_name(subnet_id) rescue ""
      end
      subnet_name
    end

    def format_provider_id(subnet_id)
      new_subnet_id = ""
      if subnet_id.include?("/providers/Microsoft.Network/virtualNetworks/subnets/")
        new_subnet_id = subnet_id # correct subnet id format, do nothing
      else
        i = subnet_id.index("Microsoft.Network/virtualNetworks")
        new_subnet_id = "#{subnet_id[0..(i-1)]}Microsoft.Network/virtualNetworks/subnets/#{Parsers::Azure::ServiceNameParser.parse_vnet_name(subnet_id)}/#{Parsers::Azure::ServiceNameParser.parse_subnet_name(subnet_id)}"
        CSLogger.info "vnet: #{Parsers::Azure::ServiceNameParser.parse_vnet_name(subnet_id)}, new_subnet_id--- #{new_subnet_id}"
      end
      new_subnet_id
    end
  end
end
