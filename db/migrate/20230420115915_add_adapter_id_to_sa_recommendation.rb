class AddAdapterIdToSaRecommendation < ActiveRecord::Migration[5.1]
  def change
    add_column :sa_recommendations, :adapter_id, :uuid
  end
end
