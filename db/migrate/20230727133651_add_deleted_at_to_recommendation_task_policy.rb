class AddDeletedAtToRecommendationTaskPolicy < ActiveRecord::Migration[5.2]
  def change
    add_column :recommendation_task_policies, :state, :text, default: 'active'
  end
end
