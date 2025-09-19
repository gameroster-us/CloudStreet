module Services
  module Network
    module InternetGatewayRepresenter
      module AWSRepresenter
include Roar::JSON
include Roar::Hypermedia
        include ServicesRepresenter
        include InternetGatewayRepresenter
        
        # attributes from data
        
        # attibutes from provider_data
        property :internet_gateway_id
        property :vpc_id
        property :tags 
        property :service_tags
        
        property :list_attributes

        def internet_gateway_id
          self.parsed_provider_data['id'] rescue ""
        end

        def vpc_id
          self.parsed_provider_data['attachment_set']['vpcId'] rescue ""
        end  

        def list_attributes
          ['name', 'state', 'vpc_id']
        end
          
      end
    end
  end
end  