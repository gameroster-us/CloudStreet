class AddColumToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :interval_time, :integer
    add_column :tasks, :time_zone,  :hstore, :default => {}
    add_column :tasks, :region_ids, :string, array: true, default: []
  end
end
