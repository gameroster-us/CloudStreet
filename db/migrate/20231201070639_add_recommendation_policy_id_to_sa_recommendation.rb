class AddRecommendationPolicyIdToSaRecommendation < ActiveRecord::Migration[5.2]
  def change
    add_column :sa_recommendations, :recommendation_policy_id, :uuid
  end
end
