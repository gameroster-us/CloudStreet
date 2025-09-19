class AddExcludeSpotInstancePerformBackupToRecommendationPolicy < ActiveRecord::Migration[5.2]
  def change
    add_column :recommendation_policies, :exclude_spot_instances, :boolean, default: false
    add_column :recommendation_policies, :perform_backup, :boolean, default: false
  end
end
