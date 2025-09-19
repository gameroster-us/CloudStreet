# frozen_string_literal: false

class RecommendationPolicy::Creator < CloudStreetService

  class << self

    def exec(current_tenant, current_account, params, &block)
      params[:type] = "RecommendationPolicies::#{CommonConstants::PROVIDER_MAPPER[params[:type]]}"
      recommendation_policy = RecommendationPolicy.new(params)
      recommendation_policy.tenant_id = current_tenant.id
      recommendation_policy.account_id = current_account.id
      if recommendation_policy.save
        status Status, :success, recommendation_policy, &block
      else
        status Status, :validation_error, recommendation_policy.errors.messages, &block
      end
    rescue StandardError => e
      status Status, :error, e, &block
    end

  end

end
