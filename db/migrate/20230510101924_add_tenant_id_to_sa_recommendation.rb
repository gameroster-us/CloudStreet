class AddTenantIdToSaRecommendation < ActiveRecord::Migration[5.1]
  def change
     add_column :sa_recommendations, :tenant_id, :uuid
  end
end
