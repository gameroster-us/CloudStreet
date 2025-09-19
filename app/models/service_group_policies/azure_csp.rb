# frozen_string_literal: false

module ServiceGroupPolicies
  # service group STI model for AzureCsp
  class AzureCsp < ServiceGroupPolicy

    class << self

      def model_name
        ServiceGroupPolicy.model_name
      end

    end

  end
end
