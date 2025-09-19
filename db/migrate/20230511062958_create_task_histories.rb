class CreateTaskHistories < ActiveRecord::Migration[5.1]
  def change
    create_table :task_histories, id: :uuid do |t|
      t.uuid :sa_recommendation_id, index: true
      t.uuid :user_id, index: true
      t.string :state
      t.string :comment
      t.jsonb  :assign_to
      t.timestamps
    end
  end
end
