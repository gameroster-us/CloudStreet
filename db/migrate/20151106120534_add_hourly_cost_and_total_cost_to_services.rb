class AddHourlyCostAndTotalCostToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :hourly_cost, :float
    add_column :services, :total_cost, :float
  end
end
