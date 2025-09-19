class AddLastRunAtToRecommendaitonTaskPolicy < ActiveRecord::Migration[5.2]
  def change
    add_column :recommendation_task_policies, :last_run_at, :datetime
  end
end
