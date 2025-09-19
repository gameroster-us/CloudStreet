class AddTaskDataPrepareFieldToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :data_prepared, :boolean, default: :true
  end
end
