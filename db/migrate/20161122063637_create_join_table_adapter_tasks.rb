class CreateJoinTableAdapterTasks < ActiveRecord::Migration[5.1]
  def change
   create_table :adapters_tasks, id: false do |t|
      t.uuid :adapter_id
      t.uuid :task_id
   end
  end
end
