class CreateTableServicesTask < ActiveRecord::Migration[5.1]
  def change
    create_table :services_tasks, id: :uuid do |t|
      t.uuid :service_id
      t.uuid :task_id
    end
    add_index :services_tasks, :service_id
    add_index :services_tasks, :task_id
  end
end
