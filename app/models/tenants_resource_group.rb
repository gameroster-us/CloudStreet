# Class to store specific azure resource groups that are shared to a tenant.
# If there is no entry for a Tenant in this model then that tenant has access to all resources.
class TenantsResourceGroup < ApplicationRecord
  belongs_to :tenant
  belongs_to :adapter
  belongs_to :azure_resource_group, class_name: "Azure::ResourceGroup"

end
