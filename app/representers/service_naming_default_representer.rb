module ServiceNamingDefaultRepresenter
include Roar::JSON
include Roar::Hypermedia
  property :id      
  property :service_type
  property :prefix_service_name      
  property :suffix_service_count     
  property :last_used_number         
  property :generic_service_type
  property :sub_service_type
  property :free_text
  property :last_used_names
end