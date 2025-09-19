class Service::SyncServicesRemover < CloudStreetService
  attr_reader :synced_services, :provisioned_services

  SERVICES_NOT_TO_REMOVED_AFTER_PROVISION = %w(Services::Vpc Services::Network::AvailabilityZone Services::Network::Subnet::AWS Services::Network::SubnetGroup::AWS Services::Network::SecurityGroup::AWS Services::Network::RouteTable::AWS Services::Network::InternetGateway::AWS Services::Network::LoadBalancer::AWS)
  SERVICE_TYPE_TO_CHILD_SERVICE_TYPES_MAP = {
    Services::Vpc.to_s                           => %w(Services::Network::Subnet::AWS Services::Network::LoadBalancer::AWS),
    Services::Network::AvailabilityZone.to_s     => %w(Services::Network::Subnet::AWS),
    Services::Network::Subnet::AWS.to_s          => %w(Services::Compute::Server::AWS Services::Network::LoadBalancer::AWS Services::Network::SubnetGroup::AWS Services::Network::AutoScaling::AWS),
    Services::Network::SubnetGroup::AWS.to_s     => %w(Services::Database::Rds::AWS),
    Services::Network::SecurityGroup::AWS.to_s   => %w(Services::Compute::Server::AWS Services::Database::Rds::AWS),
    Services::Network::LoadBalancer::AWS.to_s    => %w(Services::Network::AutoScaling::AWS)
    # Services::Network::InternetGateway::AWS.to_s => %w(Services::Network::Subnet::AWS Services::Network::LoadBalancer::AWS)
    # Services::Network::AutoScaling::AWS.to_s => %w(),
    # Services::Network::AutoScalingConfiguration::AWS.to_s => %w(),
    # Services::Network::RouteTable::AWS.to_s      => %w(),
  }
  SERVICE_DELETION_ORDER = [
    # "Services::Compute::Server::IscsiVolume::AWS"
    # "Services::Network::Alarm::AWS"
    # "Services::Database::Rds::AWS"
    # "Services::Network::AutoScalingConfiguration::AWS"
    # "Services::Network::AutoScaling::AWS"
    # "Services::Network::InternetGateway::AWS" # will be removed along with VPC
    "Services::Network::SubnetGroup::AWS",
    "Services::Network::SecurityGroup::AWS",
    "Services::Network::LoadBalancer::AWS",
    "Services::Network::RouteTable::AWS",
    "Services::Network::ElasticIP::AWS",
    "Services::Network::Subnet::AWS",
    "Services::Network::AvailabilityZone",
    "Services::Vpc"
    # "Services::Compute::Server::AWS"
    # "Services::Compute::Server::Volume::AWS"
  ]

  def initialize(synced_services:, provisioned_services:)
    @synced_services      = synced_services
    @provisioned_services = provisioned_services
  end

  def remove_services_after_provision
    remove_services_which_are_provisioned
    remove_services_which_have_no_child
  end

  private

  def remove_services_which_are_provisioned
    CSLogger.info "------- removing services which are provisioned"
    sync_service_id_arr = provisioned_services.map(&:sync_service_id)

    services_to_remove = synced_services.select do |s|
      CSLogger.info "Services and their delete conditions #{s.type} : #{s.name}  <===> #{SERVICES_NOT_TO_REMOVED_AFTER_PROVISION.exclude?(s.type)} #{sync_service_id_arr.include?(s.id)}   #{s.environment_service.blank?}"
      SERVICES_NOT_TO_REMOVED_AFTER_PROVISION.exclude?(s.type) &&
      sync_service_id_arr.include?(s.id) && # remove only those services which are provisioned in to environment
      s.environment_service.blank? # make sure you don't remove any service which is part of any environment
    end
    CSLogger.info "total #{services_to_remove.count} will be removed. Their uniq-types => #{services_to_remove.map(&:type).uniq}"
    CSLogger.info "Names of the services being removed #{services_to_remove.map(&:name)}"
    services_to_be_removed_from_solr = services_to_remove.group_by(&:type) 
    ::Service::ServiceDeleter.remove_services!(services_to_remove)
    remove_services_from_solr_indexes(services_to_be_removed_from_solr)
  end

  def remove_services_which_have_no_child
    CSLogger.info "------- removing services which have no child"
    vpc_removed = false
    vpc = nil
    services_to_be_removed_from_solr = []
    ordered_services(synced_services).each do |s|
      should_delete_service = (SERVICE_TYPE_TO_CHILD_SERVICE_TYPES_MAP.keys.include?(s.type) && does_service_have_no_child?(s)) # only remove those services which has no child services

      unless should_delete_service
        CSLogger.info "-----skipping removal of #{s.type} : #{s.id}"
      else
        CSLogger.info "-----removing service #{s.type} : #{s.id}"
      end
      if should_delete_service && s.type == 'Services::Vpc'
        vpc_removed = true
        vpc = Vpcs::AWS.where(adapter: s.adapter, account: s.account,region: s.region, vpc_id: s.provider_id).first
        CSLogger.info "vpc found"
      end
      if should_delete_service
        services_to_be_removed_from_solr << s
        ::Service::ServiceDeleter.remove_service!(s) 
      end
    end   
    if vpc_removed
      vpc.services.synced_services.each do |s|
        CSLogger.info "removing service #{s.name} #{s.provider_id} #{s.type}"
        services_to_be_removed_from_solr << s
        ::Service::ServiceDeleter.remove_service!(s)
      end
    end
    remove_services_from_solr_indexes(services_to_be_removed_from_solr.group_by(&:type)) if services_to_be_removed_from_solr.present?
  end

  def does_service_have_no_child?(service)
    child_services_type_arr = SERVICE_TYPE_TO_CHILD_SERVICE_TYPES_MAP[service.type]
    child_interfaces = service.self_protocol_interface.interfaces
    CSLogger.info "for service id:#{service.id} type:#{service.type} child_interfaces found are #{child_interfaces.count}"

    child_found = child_interfaces.find { |i| child_services_type_arr.include?(i.service.try(:type)) }
    CSLogger.info "found child present for interface-id:#{child_found} service-id:#{child_found.service.try(:id)} type:#{child_found.service.try(:type)}" if child_found.present?

    child_found.blank?
  end

  def ordered_services(services)
    services_map_grouped_by_type = services.group_by { |service| service.type }
    SERVICE_DELETION_ORDER.inject([]) do |ordered_service_arr, service_type|
      service_arr = services_map_grouped_by_type.delete(service_type)
      ordered_service_arr.push(*service_arr) if service_arr.present?
      ordered_service_arr
    end
  end

  def remove_services_from_solr_indexes(services_to_be_removed_from_solr)
    type_with_uuids_hash = SolrSearcher.prepare_data_hash_to_be_removed_by_id(services_to_be_removed_from_solr)
    SolrOperations::RemoveObjectsByIdFromSolrIndexWorker.perform_async(type_with_uuids_hash) if type_with_uuids_hash.present?
  end
end
