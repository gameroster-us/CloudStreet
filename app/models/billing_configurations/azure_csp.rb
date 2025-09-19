# frozen_string_literal: true

class BillingConfigurations::AzureCsp < ::BillingConfiguration
  field :subscriptions, type: Array, default: []
end
