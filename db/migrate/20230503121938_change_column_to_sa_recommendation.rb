class ChangeColumnToSaRecommendation < ActiveRecord::Migration[5.1]
  def change
    rename_column :sa_recommendations, :service_id, :provider_id
    change_column :sa_recommendations, :provider_id, :string
  end
end
