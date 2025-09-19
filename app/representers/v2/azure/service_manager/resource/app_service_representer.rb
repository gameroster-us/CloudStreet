# AKS Representer
module V2::Azure::ServiceManager::Resource::AppServiceRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include ServiceManager::Azure::ResourceRepresenter

  property :sku
  property :status
  property :app_service_plan
  property :kind
  property :hostnames
  property :app_service_plan_info
  property :price_type

  def price_type
    additional_properties['price_type'] || ''
  end

end

