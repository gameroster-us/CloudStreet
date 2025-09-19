class CreateTaskDetails < ActiveRecord::Migration[5.1]
  def change
    create_table :task_details, id: :uuid do |t|
  		t.uuid :adapter_id
      t.uuid :task_id
      t.string :type
      t.json :data
      t.string :resource_identifier
      t.timestamps
    end
    add_index :task_details, :adapter_id
    add_index :task_details, :task_id
    add_index :task_details, :type
    add_index :task_details, :resource_identifier
    add_foreign_key :task_details, :adapters, on_delete: :cascade
    add_foreign_key :task_details, :tasks, on_delete: :cascade    
  end
end
