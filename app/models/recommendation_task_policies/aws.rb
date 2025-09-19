# The following model has been replaced by RecommendationPolicies::AWS
# Keeping it here for reference until the transition is complete.
# Marked as dead code on: 2024-01-30

# frozen_string_literal: false

module RecommendationTaskPolicies
  # service group STI model for AWS
  class AWS < RecommendationTaskPolicy

    store_accessor :data, :tag_key

    class << self

      def model_name
        RecommendationTaskPolicy.model_name
      end

    end

  end
end
