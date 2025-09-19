class AddShowDefaultRecommendationToServiceAdviserConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :service_adviser_configs, :show_default_recommendation, :boolean, default: true
  end
end
