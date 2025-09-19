module Azure::Service
  def self.included(base)
    base.class_eval do
      include ServiceRepresenterName
      include Behaviors::TemplateDeployable
      include Behaviors::Costable::Azure
      belongs_to :CS_service
      belongs_to :adapter
      belongs_to :subscription
      belongs_to :resource_group, class_name: "Azure::Resource::ResourceGroup", foreign_key: "resource_group_id"
      
      accepts_nested_attributes_for :CS_service

      attr_accessor :tags, :modify_on_provider, :provider_client
    end
  end

  # used in representers for property panel on template
  def properties
    self.extend(self.service_representer(self).constantize)
    json = self.as_json(except: :properties)
    json.keys.map{|column|
      {
        "name" => column,
        "title" => column.titleize,
        "value" => json[column]
      }
    }+[{
      "name" => "resource_group_name",
      "title" => "Resource Group Name",
      "value" => Parsers::Azure::ServiceNameParser.parse_resource_group_name(self.provider_id)
    }]
  end

  # override this method
  def form_provider_id(provider_subscription_id, resource_group_name, parent_service_name="")
    "/subscriptions/#{provider_subscription_id}/resourceGroups/#{resource_group_name}/providers/#{self.class::AZURE_RESOURCE_TYPE}/#{self.name}"
  end

  # override this method
  def set_association_based_attributes(associated_services, params={})
  end
end