class AddColumnToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :schedule_type, :string
    add_column :tasks, :last_execuation_time, :datetime
    add_column :tasks, :next_execuation_time, :datetime
    add_column :tasks, :status, :string
  end
end
