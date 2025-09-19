class CreateReservationRecommendations < ActiveRecord::Migration[5.1]
  def change
    create_table :reservation_recommendations, id: :uuid do |t|
      t.references :adapter, type: :uuid, foreign_key: true
      t.uuid :subscription_id
      t.string :resource_scope 
      t.string :resource_type
      t.string :name
      t.string :region
      t.string :scope
      t.string :instance_flexibility_group
      t.string :vcpus
      t.string :ram
      t.string :term
      t.string :billing_frequency
      t.integer :recommended_quantity
      t.float :on_demand_cost
      t.float :reservation_cost
      t.float :overage_cost
      t.float :total_reservation_cost
      t.float :utilization
      t.float :net_savings
      t.string :look_back_period
      t.string :sku
      t.string :currency
      t.float :on_demand_rate
      t.float :reservation_rate
      t.string :unit_of_measure

      t.timestamps
    end
  end
end
