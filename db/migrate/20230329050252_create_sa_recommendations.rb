class CreateSaRecommendations < ActiveRecord::Migration[5.1]
  def change
    create_table :sa_recommendations, id: :uuid do |t|
      t.string :state, index: true
      t.jsonb  :assign_to, index: true
      t.uuid   :service_id, index: true
      t.string :service_type, index: true
      t.text   :assigner_comment
      t.text   :assignee_comment
      t.uuid   :account_id, index: true
      t.uuid   :user_id, index: true
      t.string :category, index: true
      t.string :type
      t.timestamps
    end
  end
end
