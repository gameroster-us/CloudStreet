class AddAdditionalCommentToTaskHistory < ActiveRecord::Migration[5.2]
  def change
    add_column :task_histories, :additional_comment, :text
  end
end
