class AccountGCPMultiRegion < ApplicationRecord
  belongs_to :account
  belongs_to :gcp_multi_regional, class_name: 'GCP::MultiRegional'

  delegate :id, :to=>:gcp_multi_regional, :allow_nil=> true, :prefix => 'multi_regional'
  delegate :name, :to=>:gcp_multi_regional, :allow_nil=> true,  :prefix => 'multi_regional'
  delegate :code, :to=>:gcp_multi_regional, :allow_nil=> true,  :prefix => 'multi_regional'

end
