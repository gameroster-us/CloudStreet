class ModifyRecommendationPolicySchema < ActiveRecord::Migration[5.2]
  def change
     remove_column :recommendation_task_policies, :assigner_comment
     remove_column :recommendation_task_policies, :additional_comment
     remove_column :recommendation_task_policies, :service_category

     add_column :recommendation_policy_criteria, :assigner_comment, :text
     add_column :recommendation_policy_criteria, :additional_comment, :text
  end
end
