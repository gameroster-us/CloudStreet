class CreateRecommendationPolicyCriteria < ActiveRecord::Migration[5.2]
  def change
    create_table :recommendation_policy_criteria, id: :uuid do |t|
      t.uuid :recommendation_task_policy_id
      t.string :service_type, array: true, default: []
      t.string :service_category
      t.jsonb  :criteria
      t.timestamps
    end
  end
end
