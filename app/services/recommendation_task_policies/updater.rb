# The following code has been replaced
# Keeping it here for reference until the transition is complete.
# Marked as dead code on: 2024-01-30

# frozen_string_literal: false

module RecommendationTaskPolicies
  class Updater < CloudStreetService
    class << self
      def call(_tenant, recommendation_task_policy, params, &block)
        modify_update_params(params)
        recommendation_task_policy.recommendation_policy_criterium = [] if params[:recommendation_policy_criterium_attributes].present?
        if recommendation_task_policy.update(params)
          status(Status, :success, recommendation_task_policy, &block)
        else
          status(Status, :validation_error, recommendation_task_policy.errors.messages, &block)
        end
      rescue StandardError => e
        status(Status, :error, e, &block)
      end

      def modify_update_params(params)
        params[:type] = RecommendationTaskPolicy::TYPE_MAPPER[params[:type].try(:downcase).try(:to_sym)]
        params
      end

    end
  end
end
