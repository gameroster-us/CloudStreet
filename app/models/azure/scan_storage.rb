# frozen_string_literal: true

module Azure
  # Store Azure Compliance Report
  class ScanStorage
    include Mongoid::Document
    include Mongoid::Attributes::Dynamic

    index({ meta_data_id: 1 })
    index({ policy_id: 1 })
    index({ adapter_id: 1 })
    index({ subscription_id: 1 })
    index({adapter_id: 1, policy_id: 1})


    field :meta_data_id
    field :policy_id
    field :adapter_id
    field :subscription_id
    field :policy_names
    field :policy_description
    field :remediation_description
    field :categories
    field :preview
    field :severity
    field :user_impact
    field :implementation_effort
    field :threats
  end
end
