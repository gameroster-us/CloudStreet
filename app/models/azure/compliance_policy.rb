
module Azure
	class CompliancePolicy < ApplicationRecord
		belongs_to :azure_compliance_check, class_name: 'Azure::ComplianceCheck'
		validates  :display_name, presence: true
	  validates  :description, presence: true
	  validates  :name, presence: true
	  validates  :policy_id, presence: true
	end
end