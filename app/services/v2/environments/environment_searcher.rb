module V2
  module Environments
    class EnvironmentSearcher < CloudStreetService

      def self.find_by_environment_id(environment_id, &block)
      	environment = Environment.includes(:default_adapter,:creator,:updator,:template,:region).find(environment_id)
      	properties_tables = CSService::RESOURCE_PROVIDER_AZURE_RECORD_MAPPER.values.map { |service_type| service_type.constantize.table_name.singularize.to_sym }
      	env_services = environment.CS_services.includes(properties_tables).group_by(&:service_type)
      	environment.categorized_azure_services = env_services.inject([]) { |services,(service_type, env_services)| services << EnvironmentServices.new(service_type,env_services); services }
	    status Status, :success, environment, &block
	    return environment
      end

      def self.find_by_environment_id_and_service_type(environment_id, service_type, &block)
        environment = Environment.find(environment_id)
        properties_tables = CSService::GENERIC_TYPE_MAPPER[service_type].constantize.table_name.singularize.to_sym rescue nil
        env_services = environment.CS_services.includes(properties_tables).where(service_type: CSService::GENERIC_TYPE_MAPPER[service_type])
        environment_services = EnvironmentServices.new(CSService::GENERIC_TYPE_MAPPER[service_type],env_services)
        status Status, :success, environment_services, &block
        return environment_services
      end


      def self.get_environment_children_services(environment_id,params, &block)
        environment = Environment.find(environment_id)
        CS_service =  CSService.find(params[:CS_service_id])
        environment.categorized_azure_services = find_children_services(environment,CS_service)
        status Status, :success, environment, &block
      end


      def self.find_children_services(environment,CS_service)
        case CS_service.service_type
        when CSService::VNET
          services = CS_service.CS_child_services.joins(:environment_CS_service).includes(:azure_subnet).where(environment_CS_services: {environment_id: environment.id}).subnets
          return [EnvironmentServices.new("Azure::Network::Subnet",services)]
        when CSService::VIRTUAL_MACHINE
          CS_children_services  = CS_service.CS_child_services.joins(:environment_CS_service).includes([:azure_disk]).where(environment_CS_services: {environment_id: environment.id}).group_by(&:service_type)
          CS_children_services  = CS_children_services.inject([]) { |services,(service_type, CS_children_services)| services << EnvironmentServices.new(service_type,CS_children_services); services }
          nic_CS_service_ids    = CS_service.associated_services.where(service_type: CSService::NETWORK_INTERFACE).pluck(:associated_CS_service_id)
          CS_children_services  << EnvironmentServices.new(CSService::NETWORK_INTERFACE,CSService.joins(:environment_CS_service).includes(:azure_network_interface).where(id: nic_CS_service_ids, environment_CS_services: {environment_id: environment.id})) unless nic_CS_service_ids.blank?
          return CS_children_services
        else
          properties_tables = CSService::RESOURCE_PROVIDER_AZURE_RECORD_MAPPER.values.map { |service_type| service_type.constantize.table_name.singularize.to_sym }
          CS_children_services = CS_service.CS_child_services.joins(:environment_CS_service).includes(properties_tables).where(environment_CS_services: {environment_id: environment.id}).group_by(&:service_type)
          return CS_children_services.inject([]) { |services,(service_type, CS_children_services)| services << EnvironmentServices.new(service_type,CS_children_services); services }
        end
      end
    end
  end
end