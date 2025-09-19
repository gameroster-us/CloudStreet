module EnvironmentChildrenServicesRepresenter
include Roar::JSON
include Roar::Hypermedia
  include ServiceRepresenterName

  property :children_services
  property :service_types
  
  def services
    collect
  end 

  def children_services
    @types = []
    final_service_attributes = Array.new
    services.map do |service|
      next if service.state.eql?('terminated') # ignore terminated services

      p "-----child_final_type------#{find_service_representer(service)}---------------" 
      arr = service.generic_type.split('::')
      @types << arr[arr.length-1]
      service_hash = service.extend(find_service_representer(service).constantize).to_hash 
      service_hash['cost_to_date'] = CostData.get_total_service_cost(service)
      service_hash['current_month_estimate'] = service.get_estimate_for_current_month rescue nil
      final_service_attributes << service_hash
    end
    return final_service_attributes  
  end 

  def service_types
    @types.uniq
  end

end
