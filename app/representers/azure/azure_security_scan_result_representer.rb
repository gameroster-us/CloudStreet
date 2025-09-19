module Azure
  module AzureSecurityScanResultRepresenter
    include Roar::JSON
    include Roar::Hypermedia
    property :id
    property :account_id
    property :adapter_id
    property :adapter_name, getter: lambda { |*| Adapters::Azure.find_by(id: adapter_id).try(:name) }
    property :region_id
    property :service_type
    property :impacted_value, as: :service_name
    property :category
    property :impact, as: :scan_status
    property :rule_type
    property :problem, as: :scan_details_desc
    property :data
    property :created_at
    property :updated_at

    def data
      []
    end
  end
end
