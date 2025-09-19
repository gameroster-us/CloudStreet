# A service is the fundamental unit of the CloudStreet platform, services have one or more
# interfaces which then allow connections between other services. A service remains
# a representation of the same base data model throughout it's lifecycle, transitioning
# between states and initating events that are acted upon.
#
# When a service has been transitioned to a particular state, this represents the
# desired state of the service - ...what about exceptions that occur?
#
# State:
#   pending - All new services start in this state, a pending service should be ignored
#             by everything except the code that's currently creating it.
#   directory - When a service is supported by a service class, an entry will be created
#             with the service in the directory state, at this point it will be available
#             to be used in a template/the template designer.
#   template - When a service is being used by a template the service will be duplicated
#              and transitions to the template state, at this point the service must be
#              associated with an account.
#   boot -
# Note:
# => generic (column): TODO
# => non_generic_services : Used for non generic template
# => generic_services : Used for generic templates

require "attribute_copier.rb"
# require './lib/wrappers/provider_wrappers/aws/tag_remote.rb'
class Service < ApplicationRecord
  include Authority::Abilities
  include Behaviors::ObjectRestricted
  include AttributeCopier
  include Behaviors::Services::NamingConventionable
  extend AWSRecord::CommonAttributeMapper
  extend Forwardable
  include Behaviors::BulkInsert
  include Behaviors::Costable::Amazon
  attr_accessor :provides, :depends, :context, :rank, :container, :properties, :sync_status, :user, :is_unallocated, :comment_count
  # attr_reader :html_options #, :generic

  default_scope  { where(deleted_at: nil) }

  # class << self
  #   attr_accessor :permits
  # end
  SERVICE_DRAW_ORDER = %w( Services::Vpc Services::Network::SecurityGroup Services::Network::AvailabilityZone Services::Network::RouteTable Services::Network::InternetGateway Services::Network::Subnet Services::Compute::Server Services::Network::ElasticIP Services::Network::SubnetGroup Services::Database::Rds Services::Network::AutoScaling Services::Network::AutoScalingConfiguration Services::Compute::Server::Volume Services::Network::NetworkInterface)

  UNDRAGABBLE_SERVICES = %w(Services::Network::SecurityGroup Services::Network::RouteTable Services::Network::ElasticIP Services::Network::InternetGateway Services::Network::SecurityGroup::AWS Services::Network::InternetGateway::AWS Services::Network::ElasticIP::AWS)
  UNDRAWABLE_SERVICES = %w(Services::Network::SecurityGroup Services::Network::ElasticIP Services::Network::SecurityGroup::AWS Services::Network::ElasticIP::AWS)

  TAGGABLE_SERVICES = %w(Services::Compute::Server Services::Network::LoadBalancer Services::Compute::Server::Volume Services::Network::AutoScaling Services::Database::Rds)
  RESUSABLE_TAGGABLE_SERVICE = %w(Services::Network::RouteTable Services::Network::SecurityGroup Services::Network::Subnet Services::Vpc)

  NEW_TAGGABLE_RESUABLE_SERVICES = TAGGABLE_SERVICES + %w(Services::Network::SecurityGroup Services::Network::RouteTable) #Services::Network::SubnetGroup ( ADD this on update Fog)

  UPDATABLE_TAGS = TAGGABLE_SERVICES + RESUSABLE_TAGGABLE_SERVICE

  TAGGED_SERVICES = %w(Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS Services::Network::LoadBalancer::AWS Services::Network::ApplicationLoadBalancer::AWS Services::Network::NetworkLoadBalancer::AWS Services::Network::AutoScaling::AWS Services::Database::Rds::AWS Services::Network::RouteTable::AWS Services::Network::SecurityGroup::AWS Services::Network::Subnet::AWS Services::Vpc Services::Network::SubnetGroup::AWS)
  CHARGEABLE_SERVICES = %W(Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS Services::Network::LoadBalancer::AWS Services::Network::ApplicationLoadBalancer::AWS Services::Network::NetworkLoadBalancer::AWS Services::Database::Rds::AWS Services::Network::ElasticIP::AWS)

  DETACHABLE_SERVICES = %W(Services::Compute::Server::Volume Services::Network::ElasticIP Services::Network::AutoScalingConfiguration)

  METRIC_STATES = %w(directory template pending terminated terminating deleting deleted)
  METRIC_SERVICES = %w(Services::Compute::Server::AWS Services::Database::Rds::AWS Services::Network::LoadBalancer::AWS Services::Compute::Server::Volume::AWS)

  MAJOR_REVISIONS = %w(created attached detached terminated added_to_environment removed_from_environment reloaded)

  BILLABLE_SERVICES = %W(Services::Network::ElasticIP::AWS Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS Services::Database::Rds::AWS Services::Network::LoadBalancer::AWS Services::Network::ApplicationLoadBalancer::AWS Services::Network::NetworkLoadBalancer::AWS Services::Container::EKS::AWS)
  ACTIVE_STATES = %W(stopped running stopping starting modifying)
  ENV_RELOAD_REJECTABLE_KEYS = ["id", "additional_properties", "sync_service_id", "selected_type", "service_tags"]
  INTERFACES = []
  AUTO_INCREMENT_SERVICES =  ["Services::Vpc", "Services::Network::LoadBalancer", "Services::Network::Subnet", "Services::Compute::Server", "Services::Compute::Server::Volume", "Services::Network::RouteTable", "Services::Network::SecurityGroup", "Services::Network::SubnetGroup", "Services::Network::AutoScaling", "Services::Network::AutoScalingConfiguration", "Services::Database::Rds", "Services::Compute::Server::IscsiVolume"]

  SERVICE_TYPES = ["Services::Network::Vpc::AWS", "Services::Network::SecurityGroup::AWS", "Services::Network::Subnet::AWS", "Services::Network::SubnetGroup::AWS","Services::Network::RouteTable::AWS", "Services::Network::LoadBalancer::AWS", "Services::Network::AutoScaling::AWS", "Services::Network::AutoScalingConfiguration::AWS", "Services::Network::InternetGateway::AWS", "Services::Compute::Server::AWS","Services::Database::Rds::AWS", "Services::Compute::Server::Volume::AWS", "Services::Network::ElasticIp::AWS",  "Services::Network::Nacl::AWS", "Services::Network::NetworkInterface::AWS", "Services::Network::ApplicationLoadBalancer::AWS", "Services::Network::NetworkLoadBalancer::AWS"]

  SERVICE_TYPES_HASH = SERVICE_TYPES.inject({}) {|h,i| h[i.split('::').reverse[1].underscore] = i; h}

  LB_SERVICE_TYPES = ["Services::Network::LoadBalancer::AWS", "Services::Network::ApplicationLoadBalancer::AWS", "Services::Network::NetworkLoadBalancer::AWS"]
  MOVE_TO_ENVIRONMENT_SERVICES = %W(Services::Compute::Server::AWS Services::Compute::Server::Volume::AWS Services::Network::ElasticIP::AWS Services::Network::NetworkInterface::AWS)
  NETWORK_SERVICES = RESUSABLE_TAGGABLE_SERVICE + %w(Services::Network::AvailabilityZone Services::Network::InternetGateway Services::Network::Nacl Services::Network::SubnetGroup)
  EXCLUDE_SERVICE_TYPES = ["Services::Network::NetworkInterface::AWS", "Services::Network::SecurityGroup::AWS"]
  COMPLIANCE_TYPES = [ "Services::Compute::Server::AWS","Services::Database::Rds::AWS","Services::Network::AutoScaling::AWS"]

  store_accessor :data
  store_accessor :additional_properties
  store_accessor :data, :sync_service_id, :selected_type, :service_tags, :provision_service_tags, :is_service_creator

  resourcify

  self.authorizer_name = "ServiceAuthorizer"

  COMMON_ATTRS_OF_SAME_ENV_SERVICES = [:provider_type, :vpc_id, :service_vpc_id, :region_id, :adapter_id, :account_id, :generic]
  SERVICE_DELETING_STATES = [:terminating, :terminated, :deleting, :deleted , :removed_from_provider]
  ERRORED_STATES = [:error, :removed_from_provider, :added_from_provider, :archived]
  NETWORK_SERVICES_MAP = ["Vpc", "SecurityGroup", "Subnet", "RouteTable", "Nacl"]

  belongs_to :adapter
  belongs_to :account
  belongs_to :parent, class_name: "Service"
  belongs_to :vpc
  belongs_to :region
  belongs_to :creator, foreign_key: :created_by, class_name: 'User'
  belongs_to :updator, foreign_key: :updated_by, class_name: 'User'
  has_one    :environment_service, dependent: :delete
  has_one    :environment, through: :environment_service
  has_many   :interfaces
  has_one    :template_service
  has_many   :service_details, :foreign_key  => "provider_id", :primary_key => :provider_id
  has_and_belongs_to_many :tasks
  has_many :connections, through: :interfaces
  before_destroy { |service| !service.state.eql?("directory") }
  before_destroy :delete_fk_associations
  has_many :snapshots


  has_many :filer_services, dependent: :delete_all
  has_many :filers, through: :filer_services
  has_and_belongs_to_many :instance_filer_volumes, join_table: "instance_filer_volumes"
  # has_many   :instance_filers
  # has_many   :filers, through: :instance_filers
  accepts_nested_attributes_for :environment_service

  # #TODO- http://blog.bigbinary.com/2012/10/11/solr-sunspot-websolr-delayed-job.html, modify the remove_from_index

  # Todo :: dev.cloudstreet.com is in test env so need to run the functionality,
  # in future we run rspec then need to change dev.cloudstreet.com's environment
  # unless Rails.env.test?
    searchable :auto_index => false, :auto_remove => false, :include => [:environment] do
      text :name_solr, :stored => true, :as => :service_name_textCS do
        self.name
      end
      text :provider_id_solr , :stored => true, :as => :service_id_textCS do
        (provider_id || "")
      end

      string :account_id
      string :state

      string :id, :stored => true
      string :region_id, :stored => true
      string :adapter_id, :stored => true

      string :search_object_id, :stored => true do
        environment ? environment.id.to_s : "unallocated"
      end

      string :search_object_name, :stored => true do
        environment ? environment.name : "unallocated"
      end

      string :object_type, :stored => true do
        environment ? "environment" : "unallocated"
      end
    # end
  end


  #delegators
  def_delegator :region, :code, :region_code

  validates :type, presence: true

  scope :generic_services, -> { where('type LIKE ?', '%::Generic::%') }
  scope :non_generic_services, -> { where.not('type LIKE ?', '%::Generic::%') }
  scope :vpcs, -> { where(generic_type: ['Services::Vpc', 'Services::Vpc::AWS']) }
  scope :route_tables, -> { where(generic_type: ['Services::Network::RouteTable', 'Services::Network::RouteTable::AWS']) }
  scope :subnets, -> { where(generic_type: ['Services::Network::Subnet', 'Services::Network::Subnet::AWS']) }
  scope :instance_servers, -> { where(generic_type: "Services::Compute::Server") }
  scope :security_groups, -> { where(generic_type: ['Services::Network::SecurityGroup', 'Services::Network::SecurityGroup::AWS']) }
  scope :subnet_groups, -> { where(generic_type: ['Services::Network::SubnetGroup', 'Services::Network::SubnetGroup::AWS']) }
  scope :availability_zones, -> { where(generic_type: ['Services::Network::AvailabilityZone', 'Services::Network::AvailabilityZone::AWS']) }
  scope :load_balancers, -> { where(generic_type: ['Services::Network::LoadBalancer', 'Services::Network::LoadBalancer::AWS']) }
  scope :auto_scallings, -> { where(generic_type: ['Services::Network::AutoScaling', 'Services::Network::AutoScaling::AWS']) }
  scope :auto_scalling_configurations, -> { where(generic_type: ['Services::Network::AutoScalingConfiguration', 'Services::Network::AutoScalingConfiguration::AWS']) }
  scope :volumes, -> { where(generic_type: "Services::Compute::Server::Volume") }
  scope :elastic_ips, -> { where(generic_type: ['Services::Network::ElasticIP', 'Services::Network::ElasticIP::AWS']) }
  scope :internet_gateways, -> { where(generic_type: ['Services::Network::InternetGateway', 'Services::Network::InternetGateway::AWS']) }
  scope :network_interfaces, -> { where(generic_type: ['Services::Network::NetworkInterface', 'Services::Network::NetworkInterface::AWS']) }
  scope :databases, -> { where(generic_type: 'Services::Database::Rds') }

  scope :unterminated, -> { where.not(state: 'terminated') }
  scope :running,   -> { where(state: :pending) }
  scope :directory, -> { where(state: :directory) }
  scope :monitored, -> { where("state != ?", "directory") }
  scope :templated,   -> { where(state: :template) }
  scope :environmented,  -> { where(state: 'environment') }
  scope :in_environment, -> { left_joins(:environment_service).where.not(environment_services: {environment_id: nil }).where.not(state: ['directory', 'template']) }
  scope :in_template, -> { left_joins(:template_service).where.not(template_services: {template_id: nil })}
  scope :servers,   -> { non_generic_services.where("type like ?", "Services::Compute%") }
  scope :for_type,  -> (klass) { where("serviceable_type = ?", klass) }
  scope :not_in,    ->(service_ids_on_aws){ where.not({provider_id: service_ids_on_aws+[nil]}) }
  scope :by_provider, -> (provider) { where(provider_type: provider) }
  scope :not_generic, -> { where(generic: false) }
  scope :provisioned, -> { where.not(provider_id: nil) } # provider_id's presense indicates the has been created on provider
  scope :by_application,  ->(app_id) { joins(:environment).where(environments: { application_id: app_id }) }
  scope :not_in_template, -> { where.not(state: 'template') }
  scope :added_from_provider,   -> { where(state: :added_from_provider) }
  scope :removed_from_provider, -> { where(state: :removed_from_provider)}
  scope :skip_deletion_states,  -> { where.not(state: SERVICE_DELETING_STATES) }
  scope :services_of_same_vpc, ->(service_obj, vpc_ids) { where(adapter_id: service_obj.adapter_id, region_id: service_obj.region_id, vpc_id: vpc_ids).where.not(id: service_obj.id) } # be sure to call on specific child class otherwise all type of services will be returned
  scope :asg_servers, -> { where("data->>'is_asg_server'=?", "true") }
  scope :template_directory, -> { directory.non_generic_services.not_generic.where.not(type: ["Services::Compute::Server::AWS", "Services::Database::Rds::AWS", "Services::Network::LoadBalancer::AWS"]) }
  scope :generic_template_directory, -> { directory.generic_services.not_generic.where.not(type: ['Services::Compute::Generic::Server::AWS', 'Services::Database::Generic::Rds::AWS', 'Services::Network::Generic::LoadBalancer::AWS']) }
  scope :filter_by_interfaces, -> (interface_id, class_name) {
    joins(:interfaces).where(interfaces: { id: interface_id }, services: { type: class_name })
  }
  scope :synced_services, -> {
    where.not({ services: { state: (['directory', 'template', 'pending' ] + SERVICE_DELETING_STATES) } })
  }
  scope :by_id, ->(id) { where(id: id).first }
  scope :by_provider_id, -> (provider_id, adapter_id, account_id) { where(provider_id: provider_id, adapter_id: adapter_id, account_id: account_id).first }
  scope :by_collective_filters, ->(provider_id, adapter, account, region_id) { where(provider_id: provider_id, adapter: adapter, account: account, region_id: region_id) }
  scope :reserved_servers, -> (availability_zone) {where("data ->>'availability_zone' = ?", availability_zone)}
  scope :aws_security_groups, -> { where(type: 'Services::Network::SecurityGroup::AWS') }
  scope :chargeable_services, -> { where('type in (?)', Service::CHARGEABLE_SERVICES) }
  scope :detachable_services, -> { where('generic_type in (?)', DETACHABLE_SERVICES) }
  scope :taggable_states, -> { where(state: ['running', 'stopped', 'environment'], generic_type: UPDATABLE_TAGS) }
  scope :active_services, -> { where.not(state: (['directory', 'template', 'pending', 'environment' ] + SERVICE_DELETING_STATES))}
  scope :active_reusable_services, -> { where.not(state: (['directory'] + SERVICE_DELETING_STATES))}
  scope :find_by_instance_type, ->(instance_types) { instance_servers.where("data ->> 'instance_types' in (?) or data ->> 'flavor_id' in (?)", instance_types, instance_types) }
  scope :find_by_rds_type, ->(instance_types) { databases.where("data ->> 'flavor_id' in (?)", instance_types ) }
  scope :undrawable_services,  -> { where('type in (?)', ["Services::Network::NetworkInterface::AWS", "Services::Network::SecurityGroup::AWS"]) }
  scope :exclude_services,  -> { where.not('type in (?)', EXCLUDE_SERVICE_TYPES) }
  scope :exclude_task_services, -> { where.not(:state=> SERVICE_DELETING_STATES + ["pending","error","archived","template"]) }
  scope :compliance_services, -> { where('type in (?)', COMPLIANCE_TYPES) }
  scope :find_with_tags, (lambda do|s_tags, tag_operator, account=nil|
    general_setting = GeneralSetting.find_by(account_id: account || CurrentAccount.account_id)
    general_setting&.is_tag_case_insensitive ? find_with_case_insensitive_tags(s_tags, tag_operator) : find_with_case_sensitive_tags(s_tags, tag_operator)
  end)
  scope :state_in, -> (states){where('state in (?)', states)}
  scope :spot_instances, ->{where("provider_data->>'lifecycle'=?","spot")}
  scope :normal_lifecycle_instances, ->{where("provider_data->'lifecycle' is null")}
  scope :has_instance_recommendation, ->{ where("data->'legacy_instance_sizing' is NOT null") }
  scope :ignored_from_categories, (lambda do |ignored_from_list = nil|
    category_str = build_ignored_categories_str(ignored_from_list)
    where("ignored_from && #{category_str}::varchar[]")
  end)

  scope :not_ignored_from, (lambda do |ignored_from_list = nil|
    category_str = build_ignored_categories_str(ignored_from_list)
    where.not("ignored_from && #{category_str}::varchar[]")
  end)

  def set_default_addtional_data
    {}
  end

  def self.protocol
    new.protocol
  end

  def connected_to(service, via_services_map)
    raise "connected_to method not implemented for #{self.class}"
  end

  def connected_via_interface_to(service)
    default_parent_interface = self.find_interface(self.protocol)
    default_child_interface = service.find_interface(service.protocol)
    parent_to_child_interface = self.find_interface(service.protocol)
    (parent_to_child_interface && parent_to_child_interface.connections.any?{|connection|
       connection.remote_interface.id.eql?(default_child_interface.id)
    })
  end


  def interfaces_includes?(service)
    self.class::INTERFACES.map(&:to_s).any?{|klass| klass.to_s.eql?(service.type) }
  end

  def self.sync_affective_services(vpc = nil)
    relation = self.joins("LEFT JOIN environment_services ON environment_services.service_id = services.id")
    if vpc.present?
      relation = relation.where({environment_services: {environment_id:  vpc.environments.pluck(:id)}})
    else
      relation = relation.where.not({environment_services: {environment_id:  nil}})
    end
    relation.where.not({ state: (['directory', 'template', 'pending' ] + SERVICE_DELETING_STATES) })
  end
  def get_validatable_name(target_name)
    return target_name unless account.naming_convention_enabled?
    removed_app_vars = target_name.gsub(/%(username|templatename|environmentname|templaterevision|soeconfiguration|soename|hostname|currentdate|volumename|dbname)%/, '')
    account_tags = self.account.tags
    removed_tag_vars = self.class.replace_tag_variables(nil, removed_app_vars, account_tags, nil)

    account_tags_keys = account_tags.pluck(:tag_key)
    acc_tag_vars = account_tags_keys.map{|a_tags| a_tags.downcase.parameterize(separator: '_')}.join('|')
    removed_wild_card_vars = removed_tag_vars.gsub(/\$\$(#{acc_tag_vars})/, '')
    removed_wild_card_vars.gsub('##','').try(:gsub, /-+/, '-').try(:gsub, /^-|-$/, '')
  end

  def environment
    self.environment_service.environment if self.environment_service
  end

  def delete_fk_associations
    self.template_service.destroy if self.template_service
    self.environment_service.destroy if self.environment_service
  end

  def services_of_same_subnet_and_not_template(vpc_id, subnet_cidr)
    vpc = Service.find_by_id vpc_id
    vpc = ::Vpc.find(vpc_id) if vpc.blank?
    # CSLogger.info "----vpc_id------#{vpc_id}---adapter id----#{adapter_id}-----#{vpc.inspect}----"
    vpc_ids = Service.where(adapter_id: adapter_id).where("data ->> 'vpc_id' = ?", vpc.data["vpc_id"]).pluck(:id)
    vpc_ids << vpc.id if vpc_ids.exclude?(vpc.id)
    self.class.services_of_same_vpc(self, vpc_ids).not_in_template.select do |other_service|
      other_service.get_subnet_cidr_from_interface == subnet_cidr
    end
  end

  def self_protocol_interface
    interfaces.where(interface_type: protocol).first
  end

  def supported_adapters
    ["Adapters::AWS"]
  end

  def properties
    []
  end

  def draw_order
    draw_type = generic_type.try(:gsub, '::AWS', '')
    SERVICE_DRAW_ORDER.index(draw_type) || SERVICE_DRAW_ORDER.length
  end

  def get_provider_updatable_tags(updatable_tags)
    selected_tags = updatable_tags.select {|updatable_tag| updatable_tag['applied_type'] == "Provider" && updatable_tag['selected_type'].to_s=="2"}
    selected_tags.each do |selected_tag|
      if selected_tag["tag_type"] == "dropdown"
        tag = Tag.find_by_account_id_and_tag_key(self.account_id,selected_tag["tag_key"])
        selected_tag["tag_value"] = tag.get_dropdown_nc_by_value(selected_tag['tag_value']) if tag.use_name_param_as_tag_value?
      end
    end
    returned_hash = selected_tags.inject({}){|hash, key, value| hash[key['tag_key']] = key["tag_value"];hash}
    returned_hash
  end


  def update_service_tag(params)
    return unless can_update_tag?
    if self.environment.environment_tags.first.selected_type.to_s=="1"
      self.service_tags = params['service_tags']
      self.data_will_change!
      self.save
    else
      current_tags = self.service_tags.nil? ? {} : get_provider_updatable_tags(self.service_tags)
      CS_tags =  self.service_tags.nil? ? {} : get_cloudstreet_tags(self.service_tags)
      delete_tag_params = current_tags.except!("Name", "environment_id")
      self.service_tags = self.service_tags.delete_if {|service_tag| CS_tags.keys.include?(service_tag['tag_key'])}
      delete_tag(delete_tag_params) unless delete_tag_params.blank?
      create_tag_params = get_provider_updatable_tags(params['service_tags'])
      response  = ::ProviderWrappers::AWS::TagRemote.new(service: self, agent: get_service_and_agent_map['agent']).create(create_tag_params) unless create_tag_params.blank?
      return unless response
      if !response.kind_of?(Excon::Response) && response.state.eql?('error')
        return response
      elsif response.data[:status].eql?(200)
        save_response!(params['service_tags'])
      end
      response
    end
  end

  def delete_tag(params)
    response  = ::ProviderWrappers::AWS::TagRemote.new(service: self, agent: get_service_and_agent_map['agent']).delete(params)
    if response && response.data[:status].eql?(200)
    end
    response
  end

  def get_cloudstreet_tags(all_tags)
    selected_tags = all_tags.select {|updatable_tag| updatable_tag['selected_type'].to_s=="1" }
    returned_hash = selected_tags.inject({}){|hash, key, value| hash[key['tag_key']] = key["tag_value"];hash}
    returned_hash
  end

  def save_response!(params)
    assoc_name = get_service_and_agent_map['assoc'].to_sym
    if assoc_name.eql?(:security_groups)
      remote_obj = get_service_and_agent_map['agent'].send(assoc_name).get_by_id(provider_id)
    else
      remote_obj = get_service_and_agent_map['agent'].send(assoc_name).get(provider_id)
    end
    if remote_obj.class.eql?(Fog::AWS::AutoScaling::Group)
      provider_tags = parse_asg_tags(remote_obj.tags)
      self.tags = provider_tags
      new_tags = provider_tags.inject([]) {|array, (k,v)| array << {"tag_key"=>k, "tag_value"=> v, "applied_type"=>"Provider", "selected_type" => 2, "tag_type" => get_value_by_key(k, 'tag_type'), "is_overridable" => get_value_by_key(k, 'is_overridable')}}
      self.service_tags.delete_if {|tag_hash| provider_tags.keys.include?(tag_hash['tag_key'])}
      self.service_tags = params.select {|tag_hash| !provider_tags.keys.include?(tag_hash['tag_key'])} + new_tags + params.select {|updatable_tag| updatable_tag['selected_type'].to_s=="1" }
      self.name = remote_obj.id
    else
      provider_tags = remote_obj.class.eql?(Fog::Compute::AWS::Subnet) ? remote_obj.tag_set : remote_obj.tags
      self.tags = provider_tags
      new_tags = provider_tags.inject([]) {|array, (k,v)| array << {"tag_key"=>k, "tag_value"=> v, "applied_type"=>"Provider", "selected_type" => 2, "tag_type" => get_value_by_key(k, 'tag_type'), "is_overridable" => get_value_by_key(k, 'is_overridable')}}
      self.service_tags.delete_if {|tag_hash| provider_tags.keys.include?(tag_hash['tag_key'])}
      cloudstreet_tag_keys = self.service_tags.collect {|hash| hash['tag_key']}
      self.service_tags = params.select {|tag_hash| !provider_tags.keys.include?(tag_hash['tag_key'])} + new_tags + params.select {|updatable_tag| updatable_tag['selected_type'].to_s=="1" }
      self.name = remote_obj.class.eql?(Fog::Compute::AWS::Subnet) ? (remote_obj.tag_set['Name'] || remote_obj.id) : (remote_obj.tags['Name'] || remote_obj.id)
    end
    self.service_tags.each do |service_tag|
      if service_tag["tag_type"] == "dropdown"
        tag = Tag.find_by_account_id_and_tag_key(self.account_id,service_tag["tag_key"])
        service_tag["tag_value"] = tag.tag_value.detect{ |v| v.include?(service_tag['tag_value']) }.split("|").last.strip rescue nil
        service_tag["naming_param"] = tag.get_dropdown_nc_by_value(service_tag['tag_value'])
        service_tag["apply_naming_param"] = tag.use_name_param_as_tag_value?
      end
    end
    self.provider_data = ProviderWrappers::AWS.parse_remote_service(remote_obj)
    self.state = "running" if self.state.eql?('error')
    self.save!
    self.reload
  end

  def get_value_by_key(key, required_param)
    if key.downcase.eql?('name') && required_param.eql?('is_overridable')
      return false
    elsif key.downcase.eql?('name') && required_param.eql?('tag_type')
      return "text"
    elsif key.downcase.eql?('environment_id') && required_param.eql?('tag_type')
      return "text"
    elsif key.downcase.eql?('environment_id') && required_param.eql?('is_overridable')
      return false
    else
      environment_tags  = self.environment.environment_tags
      tag_with_key = environment_tags.where(tag_key: key).first
      if required_param == 'is_overridable'
        tag_service_type = self.type.split('::')[-2]
        overridable_services_value  = tag_with_key.overridable_services.nil? ? [] : tag_with_key.overridable_services
        return overridable_services_value.include?(tag_service_type)
      else
        return tag_with_key.tag_type
      end
    end
  end

  def parse_asg_tags(asg_tags)
    Hash[*asg_tags.collect {|d| [d['Key'] , d['Value']]}.flatten]
  end

  def get_service_and_agent_map
    case generic_type
    when "Services::Compute::Server"
      {"assoc" => "servers", "agent" => aws_compute_agent}
    when "Services::Vpc"
      {"assoc" => "vpcs", "agent" => aws_compute_agent}
    when "Services::Compute::Server::Volume"
      {"assoc" => "volumes", "agent" => aws_compute_agent}
    when "Services::Network::RouteTable"
      {"assoc" => "route_tables", "agent" => aws_compute_agent}
    when "Services::Network::SecurityGroup"
      {"assoc" => "security_groups", "agent" => aws_compute_agent}
    when "Services::Network::Subnet"
      {"assoc" => "subnets", "agent" => aws_compute_agent}
    when "Services::Network::NetworkInterface"
      {"assoc" => "nics", "agent" => aws_compute_agent}
    when "Services::Network::LoadBalancer"
      {"assoc" => "load_balancers", "agent" => aws_elb_agent}
    when "Services::Database::Rds"
      {"assoc" => "servers", "agent" => aws_rds_agent}
    when "Services::Network::AutoScaling"
      {"assoc" => "groups", "agent" => aws_autoscaling_agent}
    when "Services::Network::ApplicationLoadBalancer", "Services::Network::NetworkLoadBalancer"
      {"assoc" => "app/nw lbs", "agent" => aws_app_nw_lb_agent}
    when "Services::Container::EKS"
      {"assoc" => "eks", "agent" => eks_agent}
    end
  end

  def can_create_tag?
    if TAGGABLE_SERVICES.include?(self.generic_type.to_s)
      return true
    elsif  NEW_TAGGABLE_RESUABLE_SERVICES.include?(self.generic_type.to_s) && self.get_associated_environments.try(:size).to_i < 2
      return true
    elsif self.generic_type.to_s.eql?('Services::Network::Subnet')
      return true
    else
      return false
    end
  end

  def can_update_tag?
    UPDATABLE_TAGS.include? self.generic_type.to_s
  end

  def create_tag
    if can_create_tag?
      if self.provision_service_tags
        tags_map = JSON.parse(self.provision_service_tags.to_json, object_class: OpenStruct)
      else
        tags_map =  get_tag_map
      end
      env_tags = {}
      self.tags ||={}
      self.service_tags =[]
      unless tags_map.blank?
        parsed_service_tags_map = parse_service_tags(tags_map)
        parsed_service_tags_map_obj = JSON.parse(parsed_service_tags_map.to_json, object_class: OpenStruct)
        if self.selected_type.to_i.eql?(2)
          ::ProviderWrappers::AWS::TagRemote.new(service: self, agent: get_service_and_agent_map['agent']).delete({})
          create_tag_on_provider(parsed_service_tags_map_obj.select {|tag_map| tag_map['applied_type'] == 'Provider'}) unless ['error','unhealthy','deleted','terminated'].include?(environment.state)
        end
        tags_hash = parsed_service_tags_map_obj.map{ |tag| [tag['tag_key'], tag['tag_value']] }
        tags_hash.each do |tag|
          tag[1] = "-" if tag.last && tag.last.empty?
          env_tags.merge!(Hash[*tag.flatten])
        end
        env_tags = parse_custom_tags(env_tags)
        env_tags.merge!(Name: name)
        basic_service_tags = [
          {
            "tag_key" => "Name",
            "tag_value" => name,
            "applied_type"=> "Provider",
            "selected_type" => 2,
            "tag_type" => "text",
            "is_overridable" => false
          }
        ]
        basic_service_tags = basic_service_tags.reject {|hash| hash['tag_key'] == "environment_id"} if RESUSABLE_TAGGABLE_SERVICE.include?(self.generic_type.to_s)
        parsed_service_tags_map += basic_service_tags
        env_tags = self.tags.merge(env_tags)
        merged_service_tags = self.service_tags + parsed_service_tags_map
        self.update(tags: env_tags, service_tags: merged_service_tags)
      else
        env_tags = {Name: name}
        parsed_service_tags_map = [
          {
            "tag_key" => "Name",
            "tag_value" => name,
            "applied_type"=> "Provider",
            "selected_type" => self.selected_type,
            "tag_type" => "text",
            "is_overridable" => false
          }
        ]
        merged_service_tags = self.service_tags + parsed_service_tags_map
        self.update(tags: env_tags, service_tags: merged_service_tags)
      end
    else
      CloudStreet.log "--------no tags creation for-----------------#{self.class}"
    end
    self.provision_service_tags = nil
    self.is_service_creator = false
    self.data_will_change!
    self.save
  end

  def get_tag_map
    applicable_type = self.generic_type.split('::').last.try(:downcase)
    if self.selected_type.to_i.eql?(1)
      CS_applicables = EnvironmentTag.cloudstreet_applicable(self.environment.id)
      CS_applicables = CS_applicables.select {|tag| tag.applicable_services.try(:collect, &:downcase).blank? || tag.applicable_services.collect(&:downcase).include?(applicable_type)}
      if !CS_applicables.first.try(:override_service_tags)
        CS_applicables = CS_applicables.each do |CS_applicable|
          overridable_services_map =  CS_applicable.overridable_services.try(:collect, &:downcase).blank? ? [] : CS_applicable.overridable_services.collect(&:downcase)
          if overridable_services_map.include?(applicable_type) && !overridable_services_map.blank?
            next(CS_applicable) unless self.service_tags
            self.service_tags.each do |service_tag|
              next(service_tag) unless service_tag['tag_key'] == CS_applicable.tag_key
              CS_applicable.tag_value = service_tag['tag_value']
              CS_applicable.naming_param = service_tag['naming_param']
            end
          else
            CS_applicables
          end
        end
      end
      CS_applicables
    elsif self.selected_type.to_i.eql?(2)
      provider_applicables = EnvironmentTag.provider_applicable(self.environment.id)
      provider_applicables = provider_applicables.select {|tag| tag.applicable_services.try(:collect, &:downcase).blank? || tag.applicable_services.collect(&:downcase).include?(applicable_type)}
      if provider_applicables.present?
        if !provider_applicables.first.try(:override_service_tags)
          provider_applicables = provider_applicables.each do |provider_applicable|
            overridable_services_map =  provider_applicable.overridable_services.try(:collect, &:downcase).blank? ? [] : provider_applicable.overridable_services.collect(&:downcase)
            if overridable_services_map.include?(applicable_type) && !overridable_services_map.blank?
              next(provider_applicable) unless self.service_tags
              self.service_tags.each do |service_tag|
                next(service_tag) unless service_tag['tag_key'] == provider_applicable.tag_key
                provider_applicable.tag_value = service_tag['tag_value']
                provider_applicable.naming_param = service_tag['naming_param']
              end
            end
          end
        end
      end
      provider_applicables
    else
      []
    end
  end

  def create_tag_on_provider(tag_map)
    ::ProviderWrappers::AWS::TagRemote.new(service: self, agent: aws_compute_agent).create(tag_map)
  end

  def parse_service_tags(servicetags)
    formatted_service_tags = servicetags.map() {|servicetag| {
        "tag_key" => servicetag.tag_key,
        "tag_value"=> servicetag.tag_value,
        "applied_type" => servicetag.applied_type,
        "selected_type" => servicetag.selected_type,
        "tag_type" => servicetag.tag_type,
        "is_overridable" => check_if_overridable(servicetag)
      }
    }
    unless is_service_creator
      formatted_service_tags = replace_tag_values(formatted_service_tags)
    end

    return formatted_service_tags.each { |servicetag| servicetag.merge!(get_other_tag_params(servicetag)) }
  end

  def check_if_overridable(service_tag)
    environment_tags = self.environment.environment_tags
    env_tag = environment_tags.where(tag_key: service_tag.tag_key).first
    return false unless env_tag
    if env_tag.overridable_services.blank?
      return false
    elsif env_tag.overridable_services.try(:collect, &:downcase).include?(self.type.split('::')[-2].downcase)
      return true
    else
      return false
    end
  end

  def get_other_tag_params(service_tag)
    return {} if service_tag["tag_type"] != "dropdown" || service_tag.blank?
    tag = Tag.find_by_account_id_and_tag_key(self.account_id,service_tag["tag_key"])

    unless tag.nil?
      return {"naming_param" => tag.get_dropdown_nc_by_value(service_tag["tag_value"]),"apply_naming_param" => tag.use_name_param_as_tag_value?}
    end
  end

  def replace_tag_values(formatted_service_tags)
    template_tags = self.environment.template.template_tags if self.environment.template.present?
    return formatted_service_tags unless template_tags
    formatted_service_tags.each do |formatted_service_tag_hash|
      next(formatted_service_tag_hash) unless formatted_service_tag_hash['is_overridable']
      detected_tag_hash = template_tags.detect {|hash| hash['tag_key'] == formatted_service_tag_hash['tag_key']}
      formatted_service_tag_hash['tag_value'] = detected_tag_hash.nil? ? formatted_service_tag_hash['tag_value'] : detected_tag_hash['tag_value']
    end
    formatted_service_tags
  end

  def parse_custom_tags(env_tags_params)
    env_tags_params.each do |k,v|
      if v && v.include?('%')
        if v == "%soeconfiguration%"
          if self.is_server?
            soeconfiguration_name = MachineImageConfiguration.find(self.image_config_id).name rescue ''
            env_tags_params[k] = soeconfiguration_name
          else
            env_tags_params[k] = ""
          end
        elsif v == "%soename%"
          if self.is_server?
            organisation_image_id = MachineImageConfiguration.find(self.image_config_id).organisation_image_id rescue ''
            soename = OrganisationImage.find(organisation_image_id).image_name rescue ''
            env_tags_params[k] = soename
          else
            env_tags_params[k] = ""
          end
        end
      end
    end
    env_tags_params
  end

  def assign_env_tags
    env_id = self.environment.id
    all_tags = get_tags_map(env_id)
    service_tags = {}
    service_tags.merge!("Name" => name, "environment_id" => env_id)
    if all_tags.any?
      CloudStreet.log "-------------Applying environment tags for #{self.class}---for----#{self.provider_id}--"
      applicable_type = self.type.split("::")[-2]
      CS_provider_only_tags = EnvironmentTag.where(environment_id: env_id, applied_type: ['Provider'])
      CS_provider_only_tags = CS_provider_only_tags.select {|tag| tag.applicable_services.blank? || tag.applicable_services.include?(applicable_type)}
      attach_env_tags(CS_provider_only_tags ,env_id) unless CS_provider_only_tags.blank?
      all_tags = all_tags.select {|tag| tag.applicable_services.blank? || tag.applicable_services.include?(applicable_type)}
      env_tags = all_tags.inject(Hash.new([])) { |hash, tag| hash[tag.tag_key] = tag.tag_value; hash }
      env_tags.merge!(provider_data['tags']) if provider_data && provider_data['tags']
      env_tags.merge!(service_tags) unless service_tags.blank?
      update(tags: env_tags)
      self.reset_service_tags
      self.save!
    else
      CloudStreet.log "-------------Applying only basic tags for #{self.class}---for----#{self.type}--"
      env_tags = {}
      env_tags.merge!(provider_data['tags']) if provider_data && provider_data['tags']
      env_tags.merge!(service_tags) unless service_tags.blank?
      update(tags: env_tags)
      self.reset_service_tags
      self.save!
    end

  rescue => e
    CloudStreet.log e.class.inspect
    CloudStreet.log e.message
    CloudStreet.log e.backtrace
  end

  def get_tags_map(env_id)
    EnvironmentTag.where(environment_id: env_id, applied_type: ['CloudStreet','Provider']) 
  end

  def attach_env_tags(tags_map, env_id)
    tags_map = tag_map_attributes(tags_map)
    tags_map.merge!("Name" => name, "environment_id" => env_id)
    case type
    when "Services::Compute::Server::Volume::AWS"
      aws_compute_agent.create_tags self.provider_data["id"], tags_map
    when "Services::Network::LoadBalancer::AWS"
      aws_elb_agent.add_tags self.provider_data["id"], tags_map
    end
  end

  def tag_map_attributes(tags_params)
     tags_params.inject(Hash.new([])) { |hash, tag| hash[tag.tag_key] = tag.tag_value; hash }
  end

  def provision_wrapper
    provision
    create_tag
  end

  def set_additional_properties!(attribs = {})
    attribs.merge!({
                     parent_id: set_parent_container_id,
                     depends: depends,
                     draggable: draggable,
                     drawable: drawable,
                     edge: false,
                     generic_type: generic_type,
                     id: id,
                     state: state,
                     primary_key: self.attributes['vpc_id'],
                     service_type: get_additional_properties_service_type,
                     vpc_id: self[:vpc_id]
    })
    self.additional_properties = attribs
  end

  # def properties=(value)
  #   @properties = value
  # end

  def draggable
    UNDRAGABBLE_SERVICES.exclude? self.generic_type
  end

  def drawable
    UNDRAWABLE_SERVICES.exclude? self.generic_type
  end

  def mark_environment_as_unhealthy!
    environment.unhealthy if environment
  end

  def mark_template_as_unhealthy!
    template_service.template.unhealthy if template_service
  end

  def self.directory_by_type(type)
    Service.where("state = 'directory' AND type = ?", type)
  end

  def self.get_metric_related_services
    where.not(state: METRIC_STATES , provider_id: nil).where(type: METRIC_SERVICES)
  end

  def container
  end

  def internal
  end

  def sink
  end

  def expose
  end

  def find_interface(protocol)
    # CSLogger.info "Searching #{self.class} for interface using #{protocol}"
    self.interfaces.find { |i| i.interface_type.eql?(protocol) }
  end

  # def add_interface(name, type, protocol)
  #   # raise "Interface #{name} not supported by #{self.class}" if type[name].nil?
  #   # CSLogger.info "Adding interface!"
  #   # protocol = protocol.new
  #   # interface = Interface.new(name: name.to_s, protocol: protocol)
  #   # interfaces << interface
  #   # interface
  # end

  def start_event
  end

  def stop_event
  end

  def depends
    [
      #Interface.new(name: 'web_depends', protocol: Protocols::IP::HTTP.new),
      #Interface.new(name: 'ip_depends', protocol: Protocols::IP::TCP.new)
    ]
  end

  def provides
    [
      #Interface.new(name: 'web_provies', protocol: Protocols::IP::HTTP.new),
      #Interface.new(name: 'ip_provides', protocol: Protocols::IP::TCP.new)
    ]
  end

  def instance_types
  end

  def connection_up(service)
  end

  def connection_down(service)
  end

  def shutdown
  end

  def terminate_service(params={})
  end

  def update
  end

  def startup
    result = provision
    return result if (result.is_a?(Hash) && result[:error]) || (result.is_a?(Boolean) && !result)

    create_tag
  end

  def provision
  end

  def display_name
    name.present? ? name : type
  end

  # TODO: Check if this works with Autoscaling
  def fetch_first_remote_service(protocol)
    self.interfaces.of_type(protocol.to_s).first.remote_interfaces.first.service rescue nil
  end

  def fetch_all_remote_services(protocol)
    self.interfaces.of_type(protocol.to_s).collect do |interface|
      interface.remote_interfaces.first.service rescue nil
    end.compact.uniq
  end

  def get_security_groups
    services = []
    self.interfaces.of_type("Protocols::SecurityGroup").each do |interface|
      interface.remote_interfaces.each {|i| services << i.service rescue nil}
    end
    services.compact.uniq
  end

  def connected_services
    self.interfaces.collect do |interface|
      interface.remote_interfaces.collect{|i| i.service}.reject{|s|  ["Services::Network::AvailabilityZone","Services::Vpc"].include?(s.type)} rescue nil
    end.flatten.compact.uniq
  end

  def validate_for_termination
  end

  def any_terminate_dependable_service_present?
    validate_for_termination
    self.errors.any?
  end

  def support_stop?
    false
  end

  def support_detach?
    false
  end

  def support_terminate?
    true
  end

  def check_if_can_start
    { err_msg: false }
  end

  def region_code
    self.region.try(:code)
  end

  def get_region_code
    Region.find(self.region_id).code rescue " "
  end

  def get_service_type
    self.generic_type.split('::').last.underscore
  end

  def get_generic_type_last
    self.generic_type.split('::').last
  end

  def get_service_suffixed_digit
    suffix = []
    self.name.reverse.each_char do |char|
      break if !is_number?(char)
      suffix << char
    end
    suffix.reverse.join
  end

  def is_number?(input)
    input.to_f.to_s == input.to_s || input.to_i.to_s == input.to_s
  end

  # will return all services from template, environment and synced
  def get_all_services_from_same_vpc
    self.account.services.where(region: self.region, vpc_id: self.vpc_id, adapter_id: self.adapter_id)
  end

  def get_all_services_from_same_vpc_of_same_type
    get_all_services_from_same_vpc.where(type: self.type.to_s)
  end

  def set_parent_container_id
    "set_parent_container_id method not implemented for #{self.type}"
  end

  def remote_provider
    self.type.split("::").last
  end

  def is_environmented?
    (self.state != 'directory') && (self.state != 'template') && (self.environment_service.present?)
  end

  def is_synced_service?
    ( ['directory', 'template', 'pending', 'terminated', 'terminating', 'removed_from_provider'].exclude?(self.state) ) && self.environment.blank?
  end

  def is_environmented_and_not_deleted?
    is_environmented? && ['terminating', 'terminated', 'deleting', 'deleted'].exclude?(self.state)
  end

  # rubocop:disable HashSyntax
  state_machine initial: :pending do

    event :directory do
      transition :pending => :directory
    end

    around_transition on: :directory do |service, transition, block|
      #CloudStreet.log "transitioning from #{service.state} to directory"
      block.call
    end

    event :template do
      transition [:pending, :directory, :removed_from_provider] => :template
    end

    around_transition on: :template do |service, transition, block|
      #CloudStreet.log "transitioning from #{service.state} to template"
      block.call
    end

    # event :provision?
    event :environmented do
      transition [:pending, :directory, :template] => :environment
    end

    around_transition on: :environment do |service, transition, block|
      #CloudStreet.log "transitioning from #{service.state} to environment"
      block.call
    end

    event :start do
      transition [:unerrored, :environment, :stopped, :error, :terminated] => :starting
    end

    around_transition on: :start do |service, transition, block|
      #CloudStreet.log "transitioning from #{service.state} to starting"
      block.call
    end

    event :started do
      transition [:starting, :modifying, :added_from_provider] => :running
    end

    event :modifying do
      transition [:error, :running] => :modifying
    end

    event :removed_from_provider do
      transition [ :unerrored, :stopped, :error, :terminating, :running, :modifying, :paused, :stopping, :deleting, :stopped, :template, :environment, :pending, :terminated ] => :removed_from_provider
    end

    after_transition on: :removed_from_provider do |service, transition|
      unless service.environment.nil?
        current_user_id = service.created_by
        service.mark_environment_as_unhealthy!
        revision_data = service.environment.prepare_revision_data(event: 'DeletedFromProvider', service: service)
        Events::Service::DeletedFromProvider.create({
                                                      account_id: service.account_id,
                                                      service_id: service.id,
                                                      user_id: current_user_id,
                                                      environment: service.environment,
                                                      revision_data: revision_data
        })
      end
    end

    event :synced_service_environmented do
      transition all - [:added_from_provider, :directory] => :added_from_provider
    end

    after_transition on: :synced_service_environmented do |service, transition|
      current_user = transition.args.first[:synchonized_by]
      service.mark_environment_as_unhealthy!
      Events::Service::AddedFromProvider.create_from_service(service, current_user)
    end

    event :reboot do
      transition all - [:rebooting, :directory] => :rebooting
    end

    event :rebooted do
      transition :rebooting => :running
    end

    state :upgrading do
      transition to: :running, on: [:error, :running]
    end

    state :renaming do
      transition to: :running, on: [:error, :rebooting]
    end

    around_transition on: :started do |service, transition, block|
      #CloudStreet.log "transitioning from #{service.state} to running"
      block.call
    end

    event :error do
      transition all - [:directory, :template] => :error
    end

    around_transition on: :error do |service, transition, block|
      CloudStreet.log "transitioning from #{service.state} to error :("
      block.call
    end

    event :unerror do
      transition :error => :unerrored
    end

    event :pause do
      transition :running => :paused
    end

    event :resume do
      transition :paused => :running
    end

    event :stop do
      transition [:error, :running] => :stopping
    end

    around_transition on: :stop do |service, transition, block|
      CloudStreet.log "Stop has been called on service! :o"
      block.call
    end

    event :stopped do
      transition [:error, :stopping] => :stopped
    end

    event :terminate do
      transition [:unerrored, :error, :stopping, :stopped, :running, :removed_from_provider, :environment] => :terminating
    end

    event :terminated do
      transition [:unerrored, :terminating, :environment] => :terminated
    end

    event :remove do
      transition [:pending, :environment, :created, :terminated] => :deleting
    end

    event :deleted do
      transition deleting: :deleted
    end

  end

  def fetch_remote_services(protocol)
    remote_services = []
    self.interfaces.of_type(protocol.to_s).each do |interface|
      remote_services << interface.remote_interfaces.map { |ri| ri.service }
    end
    remote_services.flatten.compact.uniq
  end

  def fetch_child_services(service_type)
    default_interface = get_default_interface
    return [] if default_interface.blank?
    default_interface.interfaces.inject([]) do |memo, ri|
      memo << ri.service if ri.service.try(:type) == service_type.to_s
      memo
    end
  end

  def fetch_all_child_services
    default_interface = get_default_interface
    return [] if default_interface.blank?
    default_interface.interfaces.inject([]) { |memo, ri| memo << ri.service }
  end

  def initialize_interface_and_connection(interface_type:, depends:, remote_service:)
    interface_type = interface_type.to_s
    remote_service_interface = remote_service.interfaces.where(interface_type: interface_type).first
    interface = initialize_interface(interface_type: interface_type, depends: !remote_service_interface.depends)
    initialize_connection(interface, remote_service_interface)
  end

  def initialize_interface(interface_type:, depends:)
    new_interface = Interface.new({ name: self.name, interface_type: interface_type.to_s, depends: depends, service_id: self.id })
    self.interfaces << new_interface
    new_interface
  end

  def initialize_connection(interface_one, interface_two)
    child, parent = interface_one.depends ? [interface_one, interface_two] : [interface_two, interface_one]
    child.connections << Connection.new(interface_id: child.id, remote_interface_id: parent.id)
  end

  def update_provider_data_from_provider(changed_fields:, id_method_name: :id)
    provider_service = get_remote_service
    raise CloudStreetExceptions::ServiceAbsentOnProvider.new(self, absent_service: self, event: :update_provider_data_from_provider) if provider_service.blank?
    changed_fields.each do |field_name|
      field_value = provider_service.send(field_name)
      self.send("#{field_name}=", field_value)
    end
    self.save!
    save_provider_data!(provider_service.to_json, provider_service.send(id_method_name))
  end

  def get_default_interface
    self.interfaces.where(depends: false, interface_type: self.protocol).first
  end

  def fetch_availability_zone_name
    az_service_obj = fetch_remote_services('Protocols::AvailabilityZone').first
    az_service_obj.try :code
  end

  def assign_updatable_attributes(attr_map)
    updatable_attrs = self.class::UPDATABLE_ATTRS rescue nil
    if updatable_attrs.blank?
      CloudStreet.log "-----------ERROR: UPDATABLE_ATTRS is not defined for class #{self.class.inspect} \n #{caller.join("\n")}"
      return
    end
    updatable_attrs.each do |updatable_attr_name|
      new_value          = attr_map[updatable_attr_name]
      attr_update_method = "#{updatable_attr_name}="

      self.send attr_update_method, new_value
    end
  end

  def is_internet_gateway?
    self.kind_of?(Services::Network::InternetGateway)
  end

  def is_route_table?
    self.kind_of?(Services::Network::RouteTable)
  end

  def is_nacl?
    self.kind_of?(Services::Network::Nacl)
  end

  def is_eni?
    self.kind_of?(Services::Network::NetworkInterface)
  end

  def is_subnet?
    self.kind_of?(Services::Network::Subnet)
  end

  def is_subnet_group?
    self.kind_of?(Services::Network::SubnetGroup)
  end

  def is_vpc?
    self.kind_of?(Services::Vpc)
  end

  def is_sg?
    self.kind_of?(Services::Network::SecurityGroup)
  end

  def is_server?
    self.kind_of?(Services::Compute::Server)
  end

  def is_rds?
    self.kind_of?(Services::Database::Rds)
  end

  def is_autoscaling?
    self.kind_of?(Services::Network::AutoScaling)
  end

  def is_autoscaling_configuration?
    self.kind_of?(Services::Network::AutoScalingConfiguration)
  end

  def is_volume?
    self.kind_of?(Services::Compute::Server::Volume)
  end

  def is_loadbalancer?
    self.kind_of?(Services::Network::LoadBalancer)
  end

  def is_elastic_ip?
    self.kind_of?(Services::Network::ElasticIP)
  end

  def is_network_interface?
    self.kind_of?(Services::Network::NetworkInterface)
  end

  def find_or_create_default_interface_connections
    begin
      self.interfaces.find_or_create_by(depends: false, interface_type: self.protocol) do |interface|
        interface.name = self.name
      end
    rescue Exception => e
      CloudStreet.log("ERROR:  Unable to create default interface for service #{self.type} #{self.name} with id #{self.id}")
      CloudStreet.log(e.message)
      CloudStreet.log(e.backtrace)
    end
  end

  def protocol
  end

  def is_created_and_not_in_error?
    !self.error? && self.provider_data.present?
  end

  def find_or_create_interface_connections(&services_context)
    CloudStreet.log("======= 'find_or_create_interface_connections' Method not Implemented for #{self.generic_type} ================")
    # raise NotImplementedError
  end

  def attachable_environments
    if self.environment
      []
    else
      account.environments.where(region: region, default_adapter: adapter)
    end
  end

  def arr_of_child_services
    fetch_all_child_services.compact.try(:map, &:id).to_a
  end

  def associated_service_count
    default_interface = get_default_interface
    return if default_interface.blank?
    assoc_services = default_interface.interfaces.inject([]) { |memo, ri| memo << ri.service if ri.service && !SERVICE_DELETING_STATES.include?(ri.service.state.to_sym); memo }
    assoc_services.uniq.count
  end

  def data_with_name
    attributes_map = self.data || {}
    CSLogger.info "---in service.rb----attributes_map = #{attributes_map}"
    attributes_map.merge('name' => self.name)
  end

  def auto_incerement!
  end

  def has_account?(account)
    self.account.id == account.id
  end

  def reload_service(aws_service, user)
    attributes = self.class.format_attributes_by_raw_data(aws_service)
    attributes[:service_tags] ||=[]
    attributes.merge!(:service_tags => attributes[:service_tags] + self.service_tags.select {|provider_tag| provider_tag['applied_type'] == "CloudStreet" && provider_tag['selected_type'].to_s == "2"}) unless self.service_tags.blank?
    attributes.merge!(provider_data: ProviderWrappers::AWS.parse_remote_service(aws_service))
    self.assign_attributes(attributes)
    self.try(:environment).try(:update, {:updated_by => user.id})
    self.edit_service_tags{ self.save }
  end

  def edit_service_tags
    #ToDo handle use case of name tag not set
    provider_tags = self.attributes[:tags]
    return (self.service_tags.nil? ? {} : self.service_tags) unless provider_tags
    self.service_tags ||=[]
    service_provider_tags = self.service_tags.select {|provider_tag| provider_tag['applied_type'] == "Provider" && provider_tag['selected_type'].to_s == "2"}
    cloudstreet_applicable_tags = self.service_tags.select {|provider_tag| provider_tag['applied_type'] == "CloudStreet" && provider_tag['selected_type'].to_s == "2"}
    provider_tag_keys = service_provider_tags.collect {|hash| hash['tag_key']}
    self.service_tags.delete_if {|tag_hash| provider_tag_keys.include?(tag_hash['tag_key'])}
    new_provider_tags ||=[]
    provider_tags.collect do |key, value|
      new_provider_tags << {
        "tag_key" => key,
        "tag_value"=> value,
        "applied_type" => "Provider",
        "selected_type" => 2,
        "tag_type" => get_value_by_key(key, 'tag_type'),
        "is_overridable" => get_value_by_key(key, 'is_overridable')
      }
    end
    unless new_provider_tags.empty?
      self.service_tags = new_provider_tags + cloudstreet_applicable_tags
    end
    yield if block_given?
  end

  def reload_associations(service, aws_service, user)
  end

  def update_geo_for_new_service!(image_x, image_y)
    geo = parents_absolute_geometry rescue nil
    if geo.kind_of?(Hash)
      x = geo['x']
      y = geo['y']
      self.geometry ||= {}
      self.geometry['x'] = (image_x - geo['x']).abs
      self.geometry['y'] = (image_y - geo['y']).abs
      self.save
    end
  end

  def absolute_geometry
    if geometry.is_a?(Hash)
      parent_geometry = parents_absolute_geometry
      return unless parent_geometry.is_a?(Hash)
      result = {
        'x' => (geometry['x'].to_i + parent_geometry['x']),
        'y' => (geometry['y'].to_i + parent_geometry['y'])
      }
      result
    end
  end

  def find_free_space
    rel_geo = fetch_all_child_services.inject({ 'x' => 0, 'y' => 0 }) do |map, service|
      next(map) unless service.geometry.kind_of?(Hash)
      map['x'] = (service.geometry['x']) if map['x'].to_f < service.geometry['x'].to_f
      map['y'] = (service.geometry['y']) if map['y'].to_f < service.geometry['y'].to_f
      map
    end
    abs_geo = absolute_geometry
    { 'x' => (abs_geo['x'] + rel_geo['x']), 'y' => (abs_geo['y'] + rel_geo['y']) }
  end


  def update_application_variables(service_name, user, env_name=nil, tempplate=nil)
    service_name = service_name.is_a?(Array) ? service_name.first : service_name
    if self.is_server? || self.is_autoscaling_configuration?
      server_map = { "soename" => send(:get_soe_name, "soename"), "soeconfiguration" => send(:get_soe_name, "soeconfig") }
      soe_match = /\%(#{server_map.keys.join('|')})\%/
      service_name = service_name.gsub!(soe_match) do |match|
        server_map[match.delete('%')]
      end if service_name[/\%(#{server_map.keys.join('|')})\%/]

      attached_volumes = []
      interface_volume = self.interfaces.where(interface_type: "Protocols::Disk").first
      if interface_volume
        interface_volume.connections.each do |connection|
          attached_volumes << connection.remote_interface.service
        end
        attached_volumes.each do |attached_volume|
          next unless attached_volume.name.include?('%hostname%')
          attached_volume.name = attached_volume.name.gsub('%hostname%', attached_volume.get_volume_hostname)
          attached_volume.save!
        end
      end
    end


    environment_name = self.environment.name rescue ''
    template_name = self.environment.template.name rescue ''
    template_revision = self.environment.template.revision.to_s rescue ''

    valid_name_map = {
      "username" => user.username,
      "templatename" => tempplate.nil? ? template_name : tempplate.name,
      "environmentname" => env_name.nil? ? environment_name : env_name,
      "templaterevision" => tempplate.nil? ? template_revision : tempplate.revision.to_s
    }

    regex_match = /\%(#{valid_name_map.keys.join('|')})\%/
    service_name = service_name.gsub!(regex_match) do |match|
      valid_name_map[match.delete('%')]
    end if service_name[/\%(#{valid_name_map.keys.join('|')})\%/]
    self.name = service_name
    self.name_will_change!
    self.save! unless self.state.eql?('directory')
    return service_name
  end

  def get_time_and_cost(is_daily_cron=false)
    service_update_time = self.last_cost_update_time ? self.last_cost_update_time : Time.now.beginning_of_day
    total_time, total_cost= 0,0
    service_hourly_cost = self.calculate_hourly_cost
    if CHARGEABLE_SERVICES.include? self.type
      service = self
      calculation_time = Time.now
      if is_daily_cron
        service_update_time =  Time.now.beginning_of_day - 1.day if (service_update_time < Time.now.beginning_of_day - 1.day)
        calculation_time = (Time.now.beginning_of_day - 1.second)
        service_update_time = (service_update_time > calculation_time) ? (Time.now.beginning_of_day - 1.second) : service_update_time
      end
      total_time = ((calculation_time - service_update_time)/1.hour).round(3).ceil
      total_cost = total_time * service_hourly_cost
    end
    [total_time, total_cost, service_hourly_cost]
  end

  def get_cost_for_current_month_till_now
    CostData.get_total_service_cost(self)
  end

  def get_estimate_for_current_month
    return 0 unless self.running?
    # cost = (((Time.now.utc.end_of_month - Time.now.utc))/1.hour) * self.calculate_hourly_cost
    cost = (((Time.now.utc.end_of_month - Time.now.utc))/1.hour) * self.cost_by_hour
    cost ? cost.round(2) : 0
  rescue Exception => e
    0
  end

  def get_autogenerated_name(user, env)
    type = generic_type + "::AWS"  #to avoid second arg
    acc_tags = env.environment_tags.to_a.map(&:serializable_hash).each {|hash| hash['key'] = hash.delete ['tag_key']}
    service_name_format_map = Service.get_naming_default_format_map(nil, self.adapter.account, self, acc_tags)
    app_vars_replaced = self.update_application_variables(service_name_format_map[self.generic_type], user, env.name, env.template)
    if app_vars_replaced.include?('%hostname%')
      final_value = app_vars_replaced.gsub!('%hostname%', '').try(:gsub, /-+/, '-').try(:gsub, /^-|-$/, '')
      service_name_format_map[self.generic_type] = final_value
    else
      service_name_format_map[self.generic_type] = app_vars_replaced
    end
    service_name_count_map  = Service.get_last_used_name_per_type(self.adapter.account, acc_tags, service_name_format_map)
    digit = service_name_count_map[type].to_i
    next_digit = digit + 1
    name_structure = service_name_format_map[generic_type]
    name = name_structure.gsub('##',"#{'%02d'%next_digit}")
    service_name_count_map[type] = next_digit
    CloudStreet.log "----------#{self.class}-----naming convention name #{name}---#{self.type}"
    service_type_value = self.type
    service_type = self.type.eql?("Services::Database::Rds::AWS") ? ::CommonConstants::SERVICE_TYPE_MAP[service_type_value][self.engine] : ::CommonConstants::SERVICE_TYPE_MAP[service_type_value]
    new_name = self.class.update_last_used_name(self.adapter.account, user, name, service_type, {}, name_structure)
    new_name
  end

  def get_changed_properties
    old_values_map, new_values_map = (self.data_was || {}), (self.data || {})
    new_values_map['name'] = self.name
    old_values_map['name'] = self.name_was

    new_values_map.inject([]) do |memo, (attr_name, new_value)|
      old_value = old_values_map[attr_name]
      attr_changed = (old_value != new_value.to_s)
      memo << attr_name if attr_changed
      memo
    end
  end

  def can_be_attached_to_env?(environment)
    true
  end

  def move_synced_service_into_env(env)

  end

  def is_detached?
    false
  end

  def parent_services
    []
  end

  def pre_process_for_copy_template
  end

  def has_cost?
    self.state.eql?("running") ? true : false
  end

  def get_basic_service_tag
    [{
       "tag_key" => "Name",
       "tag_value" => name,
       "applied_type"=> "Provider",
       "selected_type" => 2
    }]
  end

  def self.get_report_worksheet_data(klass, account_id)
    services = Service.joins("LEFT JOIN users u2 ON u2.id = services.updated_by LEFT JOIN users u1 ON u1.id = services.created_by INNER JOIN adapters ON adapters.id = services.adapter_id INNER JOIN environment_services ON environment_services.service_id = services.id INNER JOIN environments ON environments.id = environment_services.environment_id LEFT JOIN applications ON applications.id = environments.application_id")
    .where(type: klass, account_id: account_id, state: ['running','stopped'])
    .where.not(adapters: {state: ['deleting','directory']})
    .select('services.id', 'services.name', 'services.state', 'services.created_at', 'services.updated_at',
            "services.data -> 'service_tags' as tags",
            "environments.name as environment_name",
            "coalesce(applications.name, 'NULL') as application_name",
            "adapters.name as adapter_name",
            "u1.username as created_by",
            "u2.username as modified_by")
  end


  def security_groups
    services = []
    self.interfaces.of_type("Protocols::SecurityGroup").each do |interface|
      interface.remote_interfaces.each {|i| services << i.service rescue nil}
    end
    services.compact.uniq
  end


  def security_scan(security_rules)

  end

  def remove_from_environment!
    return if (!is_volume? && !is_network_interface? && !is_elastic_ip? && !is_internet_gateway? && !is_rds?) #caution condition added for reload environment
    Connection.where(remote_interface_id: self.get_default_interface.id).delete_all
    Service::ServiceDeleter.remove_services_with_all_relations!([self])
  end

  def provider_security_groups_info
    @security_group_services = fetch_remote_services('Protocols::SecurityGroup').map { |sg| {name: sg.name, id: sg.id, group_id: sg.group_id || sg.provider_id }}
  end

  def generic_template_service?
    type.include?('Generic')
  end

  def reset_service_tags
    aws_tags = {}
    aws_tags = self.tag_set.clone if self.respond_to?(:tag_set)
    aws_tags = self.tags.clone if self.respond_to?(:tags)
    Services::ServiceHelpers::AWS.update_service_tags(self,aws_tags)
  end

  def get_monthly_estimated_cost
    if self.class.name == "MachineImage"
      if !self.cost_by_hour.blank? && self[:root_device_type] == "ebs"
        return self.cost_by_hour*24*30 rescue 0.0
      else
        return 0.0
      end
    elsif(self.state.eql?('stopped') && self.type.eql?('Services::Compute::Server::AWS'))
      self.data["attached_volumes_cost"] * 24 * 30 rescue 0.0
    else
      self.cost_by_hour*24*30 unless self.cost_by_hour.blank?
    end
  end
  
  private

  def get_hostname
    if Rails.env == 'development'
      'dev.cloudstreet.com'
    elsif Rails.env == 'staging'
      'staging.cloudstreet.com'
    else
      'cloudstreet.com'
    end
  end

  def parents_absolute_geometry
    parent_service.try :absolute_geometry
  end

  def get_additional_properties_service_type
    self.generic_type.split('::').last.downcase
  end

  def wait_till_terminated(timeout_time = 10.minutes)
    Timeout::timeout(timeout_time) do
      while get_remote_service() do
          CloudStreet.log('waiting..')
          sleep(30);
        end
      end
    rescue Timeout::Error => e
      CSLogger.error('timed out.')
    end

    def parent_subnets_provider_ids
      parent_subnets_providers.map { |subnet| subnet.provider_id }
    end

    def parent_subnets_providers
      # TO DO refactor following
      # And check if "self.interfaces.of_type(Protocols::subnet)" is always single value?
      subnets = []
      self.interfaces.of_type('Protocols::Subnet').each do |subnet_interface|
        subnets << subnet_interface.remote_interfaces.map { |ri| ri.service }
      end
      subnets.flatten.uniq
    end

    def wait_till_ready service_obj
      service_obj.wait_for do
        print "."
        ready?
      end
    end

    def wait_till_sidekiq_ready service_obj
      begin
        status = Timeout::timeout(45.minutes) do
          while service_obj.state != "available" do
              print "."
              service_obj.reload
              sleep(1.minute)
            end
          end
        rescue Timeout::Error
          CloudStreet.log "#{service_obj} took more than 45 minutes to create RDS ..... so Recued timeout"
        end
      end

      # loading it lazily because it's external service
      def aws_compute_agent
        @aws_compute_agent ||= adapter.connection(regions_code)
      end

      def aws_rds_agent
        @aws_rds_agent ||= adapter.connection_rds(regions_code)
      end

      #need to optimize n+1 query here
      def aws_elb_agent
        r = Region.find(region_id)
        @aws_elb_agent ||= adapter.connection_elb(r.code)
      end

      def aws_autoscaling_agent
        @aws_autoscaling_agent ||= adapter.connection_autoscaling(regions_code)
      end

      def aws_iam_agent_no_region
        @aws_iam_agent ||= adapter.try(:connection_iam)
      end

      def aws_iam_agent
        @aws_iam_agent ||= adapter.connection_iam(regions_code)
      end

      def aws_app_nw_lb_agent
        @aws_app_nw_lb_client ||=  adapter.connection_v2_elb_client(region_code)
      end

      def eks_agent
        @aws_eks_client ||=  adapter.connection_eks_client(region_code)
      end

      def regions_code
        environment.region.code rescue region.code
      end

      def save_provider_data! provider_data, provider_id
        self.provider_data = provider_data.is_a?(String) ? JSON.parse(provider_data) : provider_data
        self.provider_id = provider_id
        self.provider_created_at = self.provider_data["created_at"] unless provider_data.blank? && provider_data["created_at"].blank?
        save!
      end

      def provider_vpc_id
        self.interfaces.of_type('Protocols::Vpc').first.remote_interfaces.first.service.data["vpc_id"] rescue nil
      end

      def parent_vpc_id
      first_remote_service = fetch_remote_services('Protocols::Vpc')
        if first_remote_service.present?
          first_remote_service.first.id
        else
          nil
        end
      end

      def provider_subnet_id
        self.interfaces.of_type('Protocols::Subnet').first.remote_interfaces.first.service.provider_id rescue nil
      end

      def provider_subnet_group_id
        subnet_group_service = self.environment.services.find(self.subnet_group_id)
        subnet_group_service.provider_id
      end

      # returns array of associated security groups id
      def provider_security_group_ids
        @security_group_services ||= fetch_remote_services('Protocols::SecurityGroup').map { |sg| sg.group_id || sg.provider_id }
      end

      # def provider_id_solr
      #   self.class.name != "Services::Vpc" ? provider_id : ""
      # end

      # obvious methods
      class << self

        def get_naming_default_format_map(template, account, service=nil, provision_tags)
          account.get_naming_default_format_map(template, service, provision_tags)
        end

        def get_last_used_name_per_type(account, provision_tags=nil, service_name_format_map=nil)
          prefix_service_names = service_name_format_map.nil? ? account.get_prefix_service_names_by_type(provision_tags) : service_name_format_map
          @memo = {"Services::Network::RouteTable::AWS"=>0, "Services::Compute::Server::Volume::AWS"=>0, "Services::Network::AutoScaling::AWS"=>0, "Services::Network::AutoScalingConfiguration::AWS"=>0, "Services::Network::SubnetGroup::AWS"=>0, "Services::Database::Rds::AWS"=>0, "Services::Compute::Server::AWS"=>0, "Services::Network::SecurityGroup::AWS"=>0, "Services::Network::Subnet::AWS"=>0, "Services::Network::LoadBalancer::AWS"=>0}
          where(account_id: account.id).in_environment.inject(@memo) do |memo, s|
            if s.data && s.data['name_free_text']
              length = (s.data['name_free_text'].length + 1)* -1
              name = s.name.slice(0..length)
            else
              name = s.name
            end
            if s.type == "Services::Database::Rds::AWS"
              parsed_name_rds = prefix_service_names[s.generic_type].is_a?(String) ? (/\A(#{(Regexp.quote prefix_service_names[s.generic_type]).gsub('\\#\\#', '([\d]+)')})\z/) : prefix_service_names[s.generic_type]#get_rds_naming_regex(account,s,provision_tags)
              next(memo) unless name =~  parsed_name_rds
            else
              parsed_name = prefix_service_names[s.generic_type].is_a?(String) ? (/\A(#{(Regexp.quote prefix_service_names[s.generic_type]).gsub('\\#\\#', '([\d]+)')})\z/) : prefix_service_names[s.generic_type]
              next(memo) unless name =~ parsed_name
            end
            digit = $2.to_i.nil? ? 0 : $2.to_i
            memo[s.type] = digit if digit > memo[s.type]#get the last largest digit
            memo
          end
          network_map = { "SecurityGroups::AWS" => "Services::Network::SecurityGroup", "Subnets::AWS" => "Services::Network::Subnet" }
          network_map.each do|network_key, network_value|
            network_key.constantize.where(account_id: account.id).where(state: 'available').inject(@memo) do |memo, s|
              if s.data && s.data['name_free_text']
                length = (s.data['name_free_text'].length + 1)* -1
                name = s.name.slice(0..length)
              else
                name = s.name
              end
              parsed_name = prefix_service_names[network_map[s.type]].is_a?(String) ? (/\A(#{(Regexp.quote prefix_service_names[network_map[s.type]]).gsub('\\#\\#', '([\d]+)')})\z/) : prefix_service_names[network_map[s.type]]
              next(memo) unless name =~ parsed_name
              digit = $2.to_i.nil? ? 0 : $2.to_i
              memo[network_map[s.type] + '::AWS'] = digit if digit > memo[network_map[s.type] + '::AWS']#get the last largest digit
              memo
            end
          end
          @memo
        end

        def get_rds_naming_regex(account,s,provision_tags)
          rds_naming = account.service_naming_defaults.where(generic_service_type: 'Rds').where(sub_service_type: s.data['engine']).order('created_at').first.prefix_service_name
          rds_naming = ServiceNamingDefault.get_name(account.service_naming_defaults.first, rds_naming, rds=true, provision_tags)
          rds_naming = (Regexp.quote rds_naming).gsub('\\#\\#', '([\d]+)')
          /\A(#{rds_naming})\z/
        end

        def used_in_environment?(ds_record)
          where({
                  type: ds_record.class::SERVICE_CLASS,
                  provider_id: ds_record.provider_id,
                  adapter_id: ds_record.adapter_id,
                  region_id: ds_record.region_id
          }).in_environment.present?
        end

        #Override this method to return a hash of additional properties to be recorded for a service
        def fetch_additional_data(remote_service)
          {}
        end

        #Should be called only for sync- Override this method to return a hash of additional properties to be recorded for a service
        def fetch_additional_data_for_sync(remote_service_id, adapter, region_code, options={})
          {}
        end

        def format_attributes_by_raw_data(aws_service)
          {
            generic_type: self.to_s.split('::AWS').first,
            generic: false
          }
        end

        def initialize_by_raw_data(raw_service)
          attributes = get_data_store_attributes(raw_service)
          attributes.merge({provider_created_at: raw_service.data["created_at"]})
          self.new attributes
        end

        def create_or_update_services_from_provider(raw_service)
          return if (!raw_service.reusable? && raw_service.used_in_environment?)
          service = build_or_edit_services_from_provider(raw_service)
          service.save!
          service
        end

        def build_or_edit_services_from_provider(raw_service)
          account = raw_service.account
          filters = {provider_id: raw_service.provider_id, type: self.to_s}
          #Note: Services associated to an environment would be handled by marking unhealthy and edit functionality pending
          service = account.services.where(filters).find{|s| s.environment.nil? }
          attributes = get_data_store_attributes(raw_service)
          attributes.merge({provider_created_at: raw_service.data["created_at"]})
          service ||= self.new
          service.cost_by_hour = raw_service.cost_by_hour
          service.set_attributes=(attributes)
          service
        end

        def build_or_edit_vpc_services_from_provider(vpc)
          get_remote_services(vpc).each do|raw_service|
            next if (!raw_service.reusable? && raw_service.used_in_environment?)|| raw_service.synced_service?
            service = initialize_by_raw_data(raw_service)
            service.cost_by_hour = raw_service.cost_by_hour
            service.is_server? ? service.update_up_and_start_time : service
            vpc.services.build(service.attributes)
          end
        end

        def get_remote_services(vpc)
          AWSRecord.send(self::AWS_RECORD_SCOPE_METHOD).where({adapter_id: vpc.adapter_id,region_id: vpc.region_id,provider_vpc_id: vpc.vpc_id,account_id: vpc.account_id}).all
        end

        # def get_filter_services_by_type(vpc)
        #   recs = AwsRecord.send(self::AWS_RECORD_SCOPE_METHOD).where({adapter_id: vpc.adapter_id,region_id: vpc.region_id,provider_vpc_id: vpc.vpc_id,account_id: vpc.account_id}).all
        #   services = []
        #   recs.each do|raw_service|
        #     next if (!raw_service.reusable? && raw_service.used_in_environment?)|| raw_service.synced_service?
        #     service = initialize_by_raw_data(raw_service)
        #     service.cost_by_hour = raw_service.cost_by_hour
        #     service.is_server? ? service.update_up_and_start_time : service
        #     services << vpc.services.build(service.attributes)
        #   end
        #   services
        # end

        def get_service_id_map(service_ids)
          where(id: service_ids).inject({}){ |memo, s| memo[s.id] = s; memo }
        end
        # Must define a method named check_if_can_detach in target class to support detachment
        def is_detachable
          define_method(:support_detach?) { true }
          define_method(:can_detach?) { |parent_id| check_if_can_detach[:error] || false }
        end

        # Must define a method named check_if_can_attach in target class to support attachment
        def is_attachable
          define_method(:support_attach?) { true }
          define_method(:can_attach?) { |parent_id| check_if_can_attach[:error] || false }

          store_accessor :data, :attach_status
          define_method(:attaching!) { self.attach_status = 'attaching' ;self.data_will_change! ; self.save! }
          define_method(:attached!)  { self.attach_status = 'attached'  ;self.data_will_change! ; self.save! }
          define_method(:detaching!) { self.attach_status = 'detaching' ;self.data_will_change! ; self.save! }
          define_method(:detached!)  { self.attach_status = 'detached'  ;self.data_will_change! ; self.save! }
          define_method(:detached?)  { self.attach_status == 'detached' }
          define_method(:detaching?) { self.attach_status == 'detaching' }
        end

        def create_connection!(interface_one, interface_two)
          child, parent = interface_one.depends ? [interface_one, interface_two] : [interface_two, interface_one]
          Connection.create!(interface_id: child.id, remote_interface_id: parent.id)
        end

        def determine_generic_type
          self.to_s.gsub(/\::([^::]+)$/, '')
        end

        def remove_services_and_snapshots(user, params)
          services_to_remove = []
          unless params[:service_ids].nil? || params[:service_ids].empty?
            services = Service.includes(:environment).where(id: params[:service_ids])
            services.each do |service|
              env = service.environment
              services_to_remove << service
              begin
                ServiceTerminatable.delay(:queue => 'api').terminate(service, params={}, user) if service
                service.update!(:last_cost_update_time => Time.now)
                CostData.update_cost_data(service.id) if env
                ServiceAdvisorLog.log_event(user, service, event_type='remove', env, nil, status='success')
              rescue Exception => e
                ServiceAdvisorLog.log_event(user, service, event_type='remove', env, nil, status='error',e)
              end
            end
          end
          unless params[:snapshot_ids].nil? || params[:snapshot_ids].empty?
            snapshots_to_be_deleted = Snapshot.where(id: params[:snapshot_ids])
            services_to_remove = services_to_remove + snapshots_to_be_deleted.to_a
            snapshots_to_be_deleted.update_all(state: "deleting")
            SnapshotArchiverWorker.perform_async(params[:snapshot_ids],user.id)
          end
          if services_to_remove.present?
            services_to_remove_from_solr = services_to_remove.group_by(&:type)
            type_with_uuids_hash = SolrSearcher.prepare_data_hash_to_be_removed_by_id(services_to_remove_from_solr)
            SolrOperations::RemoveObjectsByIdFromSolrIndexWorker.perform_async(type_with_uuids_hash)
          end
          #TODO update syncinfo
        end

        def create_deletion_failed_alert(account, service_names_array, service_type)
          service_names = service_names_array.join(', ')
          account.create_error_alert(:service_deletion_failed, { service_names: service_names , service_type: ComplianceReportService::SERVICE_TYPES_MAP[service_type]})
        end

        def get_dettached_services(filters)
          volumes = Services::Compute::Server::Volume::AWS.get_unattached_services(filters)
          launch_configs = Services::Network::AutoScalingConfiguration::AWS.get_unattached_services(filters)
          elastic_ips = Services::Network::ElasticIP::AWS.get_unattached_services(filters)
          # services = Service.where(filters).detachable_services.synced_services.group_by{|h| h[:generic_type]}
          services = volumes.merge(launch_configs)
          services = services.merge(elastic_ips)
          services || {}
        end

        def unallocate_services(user, params)
          unless params[:service_ids].nil? || params[:service_ids].empty?
            params[:service_ids].each do |service_id|
              begin
                service = Service.find service_id
                service.user = user
                env = service.environment
                ServiceUpdater.remove_from_environment!(service)
                ServiceAdvisorLog.log_event(user, service, event_type='unallocate', env, nil, status='success')
              rescue Exception => e
                ServiceAdvisorLog.log_event(user, service, event_type='unallocate', env, nil, status='error')
              end
            end
            SolrOperations::IndexObjectsIntoSolrWorker.perform_async("Service", params[:service_ids], "Synchronizers::AWS::SynchronizerService.add_services_to_environment")
          end
          unless params[:snapshot_ids].nil? || params[:snapshot_ids].empty?
            params[:snapshot_ids].each do |snapshot_id|
              snapshot = Snapshot.find(snapshot_id)
              env = snapshot.environment
              # if snapshot && snapshot.data['tags']
              snapshot.service_id = nil
              snapshot.environment_id = nil
              # snapshot.data['tags'].delete('environment_id')
              # snapshot.data_will_change!
              snapshot.last_cost_update_time = Time.now
              if snapshot.save
                CostData.update_snapshot_cost_in_cost_data(snapshot_id)
                ServiceAdvisorLog.log_event(user, snapshot, event_type='unallocate', env, nil, status='success')
              else
                ServiceAdvisorLog.log_event(user, snapshot, event_type='unallocate', env, nil, status='error')
              end
              # end
            end
            SolrOperations::IndexObjectsIntoSolrWorker.perform_async("Snapshot", params[:snapshot_ids], "Synchronizers::AWS::SynchronizerService.add_services_to_environment")
          end
          #TODO update syncinfo
        end

        def change_state_to_removed_from_provider(filters, active_service_ids)
          where(filters).in_environment.skip_deletion_states.where.not(provider_id: active_service_ids+[nil]).each do|service|
            if service.environment_service
              service.update_attribute(:state, :removed_from_provider)
              environment = service.environment_service.environment
              environment.unhealthy
            end
          end
        end

        def get_remote_service_provider_id(remote_service)
          remote_service.id
        end

        def get_dependencies_of_remote_service(remote_service)
          {}
        end

        def scan_threats(service_type,adapter,region, provider_ids, is_ct_threat)
          return unless SecurityScanner::SERVICE_TYPE_CATEGORY_MAP.keys.include?(service_type)
          scanner = SecurityScanner.new(service_type,adapter,region, Array[*provider_ids], is_ct_threat)
          scanner.start_scanning
        end

        def remove_scanned_data(service_type, adapter_id, provider_ids)
          return unless SecurityScanner::SERVICE_TYPE_CATEGORY_MAP.keys.include?(service_type)
          SecurityScanStorage.remove_scaned_data(adapter_id, provider_ids)
        end

        def find_with_case_insensitive_tags(s_tags, tag_operator)
          CSLogger.info "---------------------- INSIDE find_with_case_insensitive_tags INSENSITIVE---------------------------"
          query = ''
          s_tags.each_with_index do |h, i|
            h["tag_sign"] = "=" if h["tag_sign"].blank?
            tag_key = h['tag_key'].gsub("'", "''")
            tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
            query += tag_operator if i.positive?
            query += if !tag_value.eql?(nil)
                       h["tag_sign"].eql?('=') ? "(lower(services.data ->> 'tags'))::jsonb @> lower('#{{tag_key => tag_value}.to_json}')::jsonb " : "(NOT(lower(services.data ->> 'tags'))::jsonb @> lower('#{{tag_key => tag_value}.to_json}')::jsonb)"
                     else
                       query += h["tag_sign"].eql?('=') ? "(lower((services.data ->> 'tags'))::jsonb @> lower('#{{tag_key => nil}.to_json}')::jsonb OR (NOT lower(services.data ->> 'tags')::jsonb ?& lower('{#{tag_key}}')::text[]))" : "((NOT lower(services.data ->> 'tags')::jsonb @> lower('#{{tag_key => nil}.to_json}')::jsonb) AND lower(services.data ->> 'tags')::jsonb ?& lower('{#{tag_key}}')::text[])"
                     end
          end
          where(query)
        end

        def find_with_case_sensitive_tags(s_tags, tag_operator)
          CSLogger.info "---------------------- INSIDE find_with_case_sensitive_tags SENSITIVE---------------------------"
          query = ''
          s_tags.each_with_index do |h, i|
            h["tag_sign"] = "=" if h["tag_sign"].blank?
            tag_key = h['tag_key'].gsub("'", "''")
            tag_value = h['tag_value'].nil? ? h['tag_value'] : h['tag_value'].gsub("'", "''")
            query += tag_operator if i.positive?
            query += if !tag_value.eql?(nil)
                       h["tag_sign"].eql?('=') ? "(services.data ->> 'tags')::jsonb @> '#{{tag_key => tag_value}.to_json}' " : "(NOT(services.data ->> 'tags')::jsonb @> '#{{tag_key => tag_value}.to_json}') "
                     else
                       h["tag_sign"].eql?('=') ? "((services.data ->> 'tags')::jsonb @> '#{{tag_key => nil}.to_json}' OR(NOT(services.data ->> 'tags')::jsonb ?& '{#{tag_key}}'))" : "((NOT(services.data ->> 'tags')::jsonb @> '#{{tag_key => nil}.to_json}')AND(services.data ->> 'tags')::jsonb ?& '{#{tag_key}}') "
                     end
          end
          where(query)
        end

        def build_ignored_categories_str(ignored_from_list)
          return "ARRAY['']" if ignored_from_list.blank?

          ignored_from = 'ARRAY['
          ignored_from_list.each_with_index do |ignored, i|
            ignored_from += ', ' if i.positive?
            ignored_from += "'#{ignored}'"
          end
          ignored_from += ", 'all']"
        end

      end

end
