class TenantBillingAdapter < ApplicationRecord
  belongs_to :organisation
  belongs_to :tenant
  validates_uniqueness_of :tenant_id, scope: :organisation_id
  
end
