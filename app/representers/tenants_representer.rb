module TenantsRepresenter
  include Roar::JSON
  include Roar::Hypermedia
  include Roar::JSON::HAL


  collection(
    :tenants,
    class: Tenant,
    extend: TenantDetailInfoRepresenter)
  
  
  def tenants
    self
  end
  

end
