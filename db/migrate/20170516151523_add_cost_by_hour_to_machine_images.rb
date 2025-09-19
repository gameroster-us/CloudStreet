class AddCostByHourToMachineImages < ActiveRecord::Migration[5.1]
  def change
    add_column :machine_images, :cost_by_hour, :decimal,:precision => 23, :scale => 18, default: 0.0
  end
end
