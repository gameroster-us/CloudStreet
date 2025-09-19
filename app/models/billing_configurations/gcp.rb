# frozen_string_literal: true

class BillingConfigurations::GCP < ::BillingConfiguration
  field :projects, type: Array, default: []
end
