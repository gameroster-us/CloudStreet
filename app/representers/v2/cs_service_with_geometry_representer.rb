module V2
  module CSServiceWithGeometryRepresenter
    include Roar::JSON
    include Roar::Hypermedia 
    include V2::CSServiceRepresenter
  	
  	property :geometry, exec_context: :decorator

  	collection(
    :associated_services,
    extend: V2::AssociatedServiceRepresenter)

    def geometry
    	represented.template_CS_service.try(:geometry) || {}
    end
  end
end