# frozen_string_literal: true

# risp aws model
class RISpBillingConfigurations::AWS < ::RISpBillingConfiguration

  field :child_accounts, type: Array, default: []

  # Validations
  validates_uniqueness_of :name, presence: true, case_sensitive: false

end
