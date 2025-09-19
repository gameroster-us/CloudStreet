class AddAssignerCommentAndAdditionalCommentToPolicy < ActiveRecord::Migration[5.2]
  def change
    add_column :recommendation_task_policies, :assigner_comment, :text
    add_column :recommendation_task_policies, :additional_comment, :text
  end
end
