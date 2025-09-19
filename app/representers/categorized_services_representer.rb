module CategorizedServicesRepresenter   
include Roar::JSON
include Roar::Hypermedia

  property :provider_name

  nested :services do
    collection(
      :network,
      class: ServiceDirectoryInfo,
      extend: ServiceDirectoryInfoRepresenter,
      embedded: true)

    collection(
      :compute,
      class: ServiceDirectoryInfo,
      extend: ServiceDirectoryInfoRepresenter,
      embedded: true)

    collection(
      :database,
      class: ServiceDirectoryInfo,
      extend: ServiceDirectoryInfoRepresenter,
      embedded: true)
  end

  nested :data_services do
    collection(
      :services,
      class: Service,
      extend: ServiceDataInfoRepresenter,
      embedded: true)
  end
  # collection(
  #   :storage,
  #   class: ServiceDirectoryInfo,
  #   extend: ServiceDirectoryInfoRepresenter,
  #   embedded: true)

  link :self do
    directory_services_path
  end

  def provider_name
    if self.detect {|service| service.respond_to?(:type) && service.type.include?('Generic')}.present?
      # For Generic services, we are considering only AWS so return static value
      'AWS'
    else
      adapter_id = self.select{ |service| service.is_a? String }
      Adapter.find(adapter_id).first.class.to_s.gsub('Adapters::','').upcase
    end
  end

  def services
    included_services = [Vpcs::AWS, Services::Network::Subnet::AWS, Services::Network::ElasticIP::AWS, Services::Generic::Vpc, Services::Network::Generic::Subnet::AWS, Services::Network::Generic::ElasticIP::AWS]
    data_services = self.select{ |service| service.is_a?(Service) &&  Service::SERVICE_DELETING_STATES.exclude?(service.state.to_sym) && included_services.include?(service.class)}
    data_services.collect
  end

  def network
    non_generic_types = %w(Services::Vpc Services::Network::AvailabilityZone Services::Network::Subnet Services::Network::SubnetGroup Services::Network::LoadBalancer Services::Network::SecurityGroup Services::Network::AutoScaling Services::Network::InternetGateway Services::Network::RouteTable Services::Network::ElasticIP Services::Network::NetworkInterface)
    generic_types = %w(Services::Vpc::AWS Services::Network::AvailabilityZone::AWS Services::Network::Subnet::AWS Services::Network::SubnetGroup::AWS Services::Network::LoadBalancer::AWS Services::Network::SecurityGroup::AWS Services::Network::AutoScaling::AWS Services::Network::InternetGateway::AWS Services::Network::RouteTable::AWS Services::Network::ElasticIP::AWS Services::Network::NetworkInterface::AWS)
    network_service_types = generic_types + non_generic_types
    filtered_services = self.select{ |service| (service.instance_of?(ServiceDirectoryInfo) && network_service_types.include?(service.generic_type)) }
    filtered_services.collect
  end

  def compute
    network_service_types = %w(Services::Compute::Server Services::Compute::Server::Volume Services::Compute::Server::IscsiVolume Services::Compute::Server::InstanceFiler Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS Services::Compute::Server::IscsiVolume::AWS)
    filtered_services = self.select{ |service| (service.instance_of?(ServiceDirectoryInfo) && network_service_types.include?(service.generic_type)) }
    filtered_services.collect
  end

  def database
    network_service_types = %w(Services::Database::Rds Services::Database::Rds::AWS)
    filtered_services = self.select{ |service| (service.instance_of?(ServiceDirectoryInfo) && network_service_types.include?(service.generic_type)) }

    filtered_services.collect
  end

  def storage
    network_service_types = %w(Services::VPC Services::Network::AvailabilityZone Services::Network::Subnet::AWS)
    filtered_services = self.select{ |service| (service.instance_of?(ServiceDirectoryInfo) && network_service_types.include?(service.type)) }

    filtered_services.collect
  end
end
