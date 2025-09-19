class AssociatedService < ApplicationRecord
  include Behaviors::BulkInsert
  
  belongs_to :CS_service
  belongs_to :CS_parent_service, :foreign_key  => "associated_CS_service_id", :class_name => "CSService"

  def self.create_mock_assoc_service(associated_service, main_service)
    AssociatedService.create!({
      "associated_CS_service_id" => associated_service.id,
      "service_type" => associated_service.service_type,
      "name" => associated_service.name,
      "CS_service_id" => main_service.id
    })
  end

  def self.init_associated_service(CS_service, associated_service)
    AssociatedService.new({
      "associated_CS_service_id" => associated_service["id"],
      "service_type" => associated_service["service_type"],
      "name" => associated_service["name"],
      "CS_service_id" => CS_service["id"]
    })
  end

  def self.process_associations(service_data, associated_service_data, association_hash)
    service_provider_id = service_data["provider_id"]
    associated_service_provider_id = associated_service_data["provider_id"]
    association_service_type = associated_service_data["service_type"]
    associations = association_hash[service_provider_id]["associations"][association_service_type]
    association_hash[service_provider_id]["associations"][association_service_type] << associated_service_provider_id unless associations.include? associated_service_provider_id
    AssociatedService.init_associated_service(service_data, associated_service_data)
  end
end
