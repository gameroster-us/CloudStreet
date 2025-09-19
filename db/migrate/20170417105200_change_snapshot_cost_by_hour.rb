class ChangeSnapshotCostByHour < ActiveRecord::Migration[5.1]
  def up
  	change_column :snapshots, :cost_by_hour, :decimal,:precision => 23, :scale => 18, default: 0.0
  	change_column :services, :cost_by_hour, :decimal,:precision => 15, :scale => 10, default: 0.0
  	change_column :applications, :cost, :decimal,:precision => 12, :scale => 4, default: 0.0
  	change_column :aws_records, :cost_by_hour, :decimal,:precision => 23, :scale => 18, default: 0.0
  	change_column :cost_summaries, :blended_cost, :decimal,:precision => 15, :scale => 5, default: 0.0
  	change_column :cost_summaries, :unblended_cost, :decimal,:precision => 15, :scale => 5, default: 0.0
  	#To do
  	# change_column :costs, :blended_cost, :decimal,:precision => 15, :scale => 5, default: 0.0
  	# change_column :costs, :unblended_cost, :decimal,:precision => 15, :scale => 5, default: 0.0
  end
  def down
  	change_column :snapshots, :cost_by_hour, :float, default: 0.0
  	change_column :services, :cost_by_hour, :float, default: 0.0
  	change_column :applications, :cost, :float, default: 0.0
  	change_column :aws_records, :cost_by_hour, :float, default: 0.0
  	change_column :cost_summaries, :blended_cost, :float, default: 0.0
  	change_column :cost_summaries, :unblended_cost, :float, default: 0.0
  	# change_column :costs, :blended_cost, :float, default: 0.0
  	# change_column :costs, :unblended_cost, :float, default: 0.0
  end
end
