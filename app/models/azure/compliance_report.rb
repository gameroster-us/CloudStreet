# frozen_string_literal: true

module Azure
  # Store Azure Compliance Report
  class ComplianceReport
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    index({ policy_definition_id: 1 })
    index({ adapter_id: 1 })
    index({ subscription_id: 1 })
    index({is_compliant: 1})
    index({adapter_id: 1, policy_definition_id: 1, is_compliant: 1})
    index({"data.resourceId": 1})

    field :policy_definition_id
    field :adapter_id
    field :subscription_id
    field :is_compliant, type: Boolean
    field :data
  end
end