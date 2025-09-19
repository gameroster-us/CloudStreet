require "azure/service"
class Azure::Network::NetworkInterface < ApplicationRecord
  include Azure::Service
  include Behaviors::TemplateDeployable::Azure::Network::NetworkInterface
  self.table_name = "azure_network_interfaces"

  ASSOCIATED_SERVICE_TYPES = %w(Azure::Network::Vnet Azure::Network::Subnet Azure::Network::SecurityGroup Azure::Network::PublicIPAddress Azure::Network::LoadBalancer)

  REUSABLE = false
  AZURE_RESOURCE_TYPE = "Microsoft.Network/networkInterfaces"

  def ip_configurations
    ip_configs = read_attribute('ip_configurations')
    (ip_configs.class == String) ? JSON.parse(ip_configs) : ip_configs
  end

  def init_associations(association_hash)
    associated_services = []
    begin
      eni_metadata = {"id" => self.CS_service_id, "provider_id" => self.provider_id}

      # eni with subnet
      begin
        eni_subnet = self.ip_configurations[0]["properties"]["subnet"]["id"]
        eni_subnet = ::Azure::Network::Subnet.format_provider_id(eni_subnet)
        subnets_metadata = association_hash[eni_subnet]["info"]
        associated_services << AssociatedService.process_associations(eni_metadata, subnets_metadata, association_hash)
      rescue Exception => e
        CSLogger.error "Unable to create association of NIC: #{self.name} with subnet #{Parsers::Azure::ServiceNameParser.parse_new_subnet_name(eni_subnet)}, error: #{e.class} #{e.message} #{e.backtrace}"
      end

      # eni with Vnet
      begin
        vnet = association_hash[eni_subnet]["associations"]["Azure::Network::Vnet"][0]
        vnet_metadata = association_hash[vnet]["info"]
        associated_services << AssociatedService.process_associations(eni_metadata, vnet_metadata, association_hash)
      rescue Exception => e
        CSLogger.error "Unable to create association of NIC: #{self.name} with Vnet #{Parsers::Azure::ServiceNameParser.parse_vnet_name(vnet)}, error: #{e.class} #{e.message} #{e.backtrace}"
      end

      begin
        if self.security_group.present?
          sg_metadata = association_hash[self.security_group]["info"]
          associated_services << AssociatedService.process_associations(eni_metadata, sg_metadata, association_hash) # eni with sg
          associated_services << AssociatedService.process_associations(sg_metadata, vnet_metadata, association_hash) # sg with vnet
        end
      rescue Exception => e
        CSLogger.error "Unable to create association of NIC: #{self.name} with SG #{Parsers::Azure::ServiceNameParser.parse_sg_name(self.security_group)}, error: #{e.class} #{e.message} #{e.backtrace}"
      end

      self.ip_configurations.each do |ip_config|
        begin
          public_ip = ip_config["properties"]["public_ip_address"]
          if public_ip.present? && association_hash[public_ip["id"]].present?
            public_ip_metadata = association_hash[public_ip["id"]]["info"]
            associated_services << AssociatedService.process_associations(eni_metadata, public_ip_metadata, association_hash) # with public IP
            pip_with_vnet = AssociatedService.process_associations(public_ip_metadata, vnet_metadata, association_hash) # public IP with Vnet
            associated_services << pip_with_vnet
          end
        rescue Exception => e
          CSLogger.error "Unable to create association of NIC: #{self.name} with public ip #{Parsers::Azure::ServiceNameParser.parse_public_ip_address(public_ip['id'])}, error: #{e.class} #{e.message} #{e.backtrace}"
        end
        begin
          lb_backend_address_pools = ip_config["properties"]["load_balancer_backend_address_pools"]
          if lb_backend_address_pools.present?
            lb_backend_address_pools.each do |backend_address_pool|
              lb_name = Parsers::Azure::ServiceNameParser.parse_lb_name(backend_address_pool["id"])
              lb_provider_id = "#{backend_address_pool["id"].split(/#|#{lb_name}/).first}#{lb_name}"
              association_hash[self.provider_id]["associations"]["Azure::Network::LoadBalancer"] << lb_provider_id
            end
          end
        rescue Exception => e
          CSLogger.error "Unable to populate association of NIC: #{self.name} with LB #{Parsers::Azure::ServiceNameParser.parse_lb_name(lb_name)}, error: #{e.class} #{e.message} #{e.backtrace}"
        end
      end
    rescue Exception => e
      CSLogger.error "Error occured in building associations for service => Name: #{self.name} Type: #{self.class} Provider ID: #{self.provider_id} , #{e.class} #{e.message} #{e.backtrace}"
    ensure
      return associated_services
    end
  end

  def update_from_remote(adapter, provider_subscription_id, rg_name, client=nil)
    client = ProviderWrappers::Azure.network_management_client(adapter, provider_subscription_id) unless client.present?
    nic_data = JSON.parse(ProviderWrappers::Azure::Networks::NetworkInterfaceProvider.get(client, rg_name, self.name).to_json)
    # CSLogger.info "nic_data--- #{nic_data}"
    new_ip_configs = []
    nic_data["ip_configurations"].each do |ip_config|
      new_ip_config = {
        "name" => ip_config["name"],
        "properties" => {
          "private_ip_allocation_method" => ip_config["private_ipallocation_method"],
          "subnet" => ip_config["subnet"],
          "private_ip_address_version" => ip_config["private_ipaddress_version"],
          "private_ip_address" => ip_config["private_ipaddress"]
        }
      }
      new_ip_config["properties"].merge!({"public_ip_address" => ip_config["public_ipaddress"]}) if ip_config.has_key?("public_ipaddress")
      new_ip_config["properties"].merge!({"primary" => ip_config["primary"]}) if ip_config.has_key?("primary")
      new_ip_configs << new_ip_config
    end
    self.attributes = {
      ip_configurations: new_ip_configs
    }
    CSLogger.info "Before update---- #{self.ip_configurations}"
    self.save!
  end

  class << self
    def get_associated_services_for_tag_filter(service_id, association_hash, associated_service_ids=[])
      service_associations = association_hash["#{self}"][service_id]
      associated_service_ids.concat(service_associations.values.flatten)
      association_hash["Azure::Compute::VirtualMachine"].each do |a_service_id, associations|
        associations.each do |service_type, ids|
          if service_type == "Azure::Network::NetworkInterface" && ids.include?(service_id)
            associated_service_ids.concat([a_service_id]) # vm associations
            vm_associated_service_ids = Azure::Compute::VirtualMachine.get_associated_services_for_tag_filter(a_service_id, association_hash)
            return (associated_service_ids.concat(vm_associated_service_ids)).uniq
          end
        end
      end
      return associated_service_ids.uniq
    end
  end
end
