module V2
  module CSServiceRepresenter
include Roar::JSON
include Roar::Hypermedia

    property :id
    property :name
    property :state
    property :provider_id
    property :account_id
    property :adapter_id
    property :region_id
    property :metadata
    property :cost_summary, extend: ::Azure::CostSummaryRepresenter
    property :resource_group_name, exec_context: :decorator
    property :extra_metadata, exec_context: :decorator
    property :detail_service_type, exec_context: :decorator, as: :service_type

    def detail_service_type
      (represented.service_type == "FilerVolumes::CloudResources::NetApp") ? "Azure::Compute::VirtualMachine::InstanceFiler" : represented.service_type
    end

    def resource_group_name
       Parsers::Azure::ServiceNameParser.parse_resource_group_name(represented.provider_id)
    end

    def extra_metadata
        represented.get_extra_metadata
    end    
  end
end