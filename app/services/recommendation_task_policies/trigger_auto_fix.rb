# The following code has been replaced 
# Keeping it here for reference until the transition is complete.
# Marked as dead code on: 2024-01-30

# frozen_string_literal: false

module RecommendationTaskPolicies
  class TriggerAutoFix < CloudStreetService
    class << self
      def call(recommendation_task_policy, _params = {}, &block)
        RecommendationTaskPolicies::RecommendedResources::AWS.call(recommendation_task_policy)
        status Status, :success, { message: 'Autofix has been triggered' }, &block
      rescue StandardError => e
        status Status, :error, e, &block
      end

    end
  end
end
