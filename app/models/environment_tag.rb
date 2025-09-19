class EnvironmentTag < ApplicationRecord
  include Authority::Abilities
  self.authorizer_name = "EnvironmentTagAuthorizer"
  store_accessor :data, :naming_param
  SERVICE_TAGGABLE_TYPES = ["Services::Network::LoadBalancer::AWS", "Services::Network::Subnet::AWS", "Services::Compute::Server::AWS","Services::Compute::Server::Volume::AWS", "Services::Network::RouteTable::AWS", "Services::Network::SecurityGroup::AWS", "Services::Network::AutoScaling::AWS", "Services::Database::Rds::AWS", "Services::Compute::Server::IscsiVolume::AWS"]

  scope :get_by_environment_id, ->(environment_id){ where(environment_id: environment_id)}
  scope :get_all_services_tag, ->{ where(applicable_services: [])}
  scope :get_specific_services_tag, ->(service){ where(applicable_services: service)}
=begin
 0 - not_all
 1 - cloudstreet_only ( CloudStreet )
 2 - All ( CloudStreet + Provider )
=end 
  belongs_to :environment


  def tags_applicable_services
    tags = []
    filtered_service_taggable_types = self.applicable_services.blank? ? SERVICE_TAGGABLE_TYPES : SERVICE_TAGGABLE_TYPES.select {|a| self.applicable_services.collect(&:downcase).include?(a.downcase.split('::')[-2]) }
    filtered_service_taggable_types.each do |env_service|
     tags_hash = {}
     tag_service_type = SERVICE_TAGGABLE_TYPES.select{|a| a.split('::')[-2] == env_service.split('::')[-2]}.first
     next(env_service) if tags.collect{|tag| tag[:service_type]}.uniq.include?(tag_service_type)
     overridable_services_value  = self.overridable_services.nil? ? [] : self.overridable_services.collect(&:downcase)
     is_overridable = overridable_services_value.include?(tag_service_type.downcase.split('::')[-2])
     tags_hash.merge!(service_type: tag_service_type.split('::')[-2], is_overridable: is_overridable)
     tags_hash.merge!(overridable_services_map: get_overridable_services_map(env_service))
     tags << tags_hash
   end
   tags
  end

  def get_overridable_services_map(env_service_type)
    overridable_services_map = []
    self.environment.services.taggable_states.where(type: env_service_type).each do |env_service|
      env_service_tags = env_service.try(:service_tags)
      service_tag = env_service_tags.nil? ? {} : env_service_tags.select {|tag_hash| tag_hash['tag_key'] == self.tag_key}.first
      service_tag = service_tag.nil? ? {} : service_tag
      service_tag.merge!(service_name: env_service.name)
      overridable_services_map << service_tag 
    end
    overridable_services_map
  end

  class << self
    def provider_applicable(env_id)
      where(environment_id: env_id, applied_type: ['CloudStreet', 'Provider'], selected_type: 2)
    end

    def cloudstreet_applicable(env_id)
      where(environment_id: env_id, applied_type: ['CloudStreet', 'Provider'], selected_type: 1)
    end

    def non_mandatory_empty
      where(tag_value: " ", is_mandatory: [nil, false])
    end
  end
end
