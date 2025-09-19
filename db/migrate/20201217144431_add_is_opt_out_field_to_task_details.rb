class AddIsOptOutFieldToTaskDetails < ActiveRecord::Migration[5.1]
  def change
  	add_column :task_details, :is_opt_out, :boolean, default: :false
  end
end
