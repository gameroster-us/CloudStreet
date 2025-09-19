class AddCostByHourToVmInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_inventories,:cost_by_hour, :decimal, default: 0.0
  end
end
