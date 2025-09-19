class ServiceSynchronizationHistory < ApplicationRecord
  include Behaviors::BulkInsert
  belongs_to :account
  belongs_to :synchronization
  belongs_to :region
  belongs_to :adapter

  store_accessor :updates
  store_accessor :provider_data
  store_accessor :data
 	validates_presence_of :account_id

  scope :vpcs, -> { where(generic_type: 'Services::Vpc') }

  class << self
    def log(service,synchronization_id)
      log = self.new(synchronization_id: synchronization_id)
      assign_service_attributes(log,service)
      log.save!
    end

    def assign_service_attributes(log,service)
      log.name = service.name
      log.state = service.state
      log.provider_type = service.provider_type
      log.generic_type = service.generic_type
      log.provider_id = service.provider_id
      log.data = service.data
      log.provider_data = service.provider_data
      log.updates = service.changes
      log.adapter_id = service.adapter_id
      log.region_id = service.region_id
      log.account_id = service.account_id
      unless (service.vpc.nil? ||service.is_vpc?)
        log.provider_vpc_id = service.vpc.vpc_id 
      end
    end
   end
end