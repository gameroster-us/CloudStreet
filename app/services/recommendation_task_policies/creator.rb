# The following class has been replaced by RecommendationPolicies::Creator
# Keeping it here for reference until the transition is complete.
# Marked as dead code on: 2024-01-30

# frozen_string_literal: false

module RecommendationTaskPolicies
  class Creator < CloudStreetService
    class << self
      def call(current_tenant, params, &block)
        modify_create_params!(params)
        task_policy = RecommendationTaskPolicy.new(params)
        task_policy.tenant_id = current_tenant.id
        task_policy.account_id = current_tenant.organisation.account.id
        if task_policy.save
          status Status, :success, task_policy, &block
        else
          status Status, :validation_error, task_policy.errors.messages, &block
        end
      rescue StandardError => e
        status Status, :error, e, &block
      end

      def modify_create_params!(params)
        params[:type] = RecommendationTaskPolicy::TYPE_MAPPER[params[:type].try(:downcase).try(:to_sym)]
        params
      end

    end
  end
end
