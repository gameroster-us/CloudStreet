class CostAllocationRule < ApplicationRecord
  belongs_to :tenant
  belongs_to :account

  validates_uniqueness_of :name, scope: :account_id, presence: true, case_sensitive: false, message: 'The Name is already in use'
end
