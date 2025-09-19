class AddHourlyCostToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :cost_by_hour, :float, default: 0.0
    add_column :aws_records, :cost_by_hour, :float, default: 0.0
    add_column :snapshots, :cost_by_hour, :float, default: 0.0
  end
end
