class AddAdditionalCommentToSaRecommendations < ActiveRecord::Migration[5.2]
  def change
    add_column :sa_recommendations, :additional_comment, :text
  end
end
