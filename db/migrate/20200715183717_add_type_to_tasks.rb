class AddTypeToTasks < ActiveRecord::Migration[5.1]
  def change
  	add_column :tasks, :type, :string
  	add_index :tasks, :type
  end
end
