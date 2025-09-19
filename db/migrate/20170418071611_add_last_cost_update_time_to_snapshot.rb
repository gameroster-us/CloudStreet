class AddLastCostUpdateTimeToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :last_cost_update_time, :datetime
  end
end
