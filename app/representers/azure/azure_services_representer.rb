module Azure
  module AzureServicesRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    
    mattr_accessor :last_synced_datetime

    property :id
    property :name
    property :state
    property :resource_group_name
    property :generic_type
    property :provider_id
    property :region_id
    property :region_name
    property :adapter_id
    property :subscription_id
    property :CS_service_id
    property :properties
    property :tags, getter: lambda { |args| args[:options][:tags] }
    property :cost_summary

    def cost_summary
      CostSummaryRepresenter.last_synced_datetime = last_synced_datetime
      service = self.CS_service
      if service.present? && service.is_costable?
        service_cost_summary = service.cost_summary
        service_cost_summary.extend(Azure::CostSummaryRepresenter) if service_cost_summary.present?
      end
    end

    def region_code
      self.location
    end

    def region_name
      Region::AZURE_MAP[self.location]
    end

   	def generic_type
   		self.class.name
   	end

    def state
      "created"
    end

    def resource_group_name
      Parsers::Azure::ServiceNameParser.parse_resource_group_name(self.provider_id)
    end
  end
end
