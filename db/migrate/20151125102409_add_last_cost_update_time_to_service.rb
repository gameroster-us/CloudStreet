class AddLastCostUpdateTimeToService < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :last_cost_update_time, :datetime
  end
end
