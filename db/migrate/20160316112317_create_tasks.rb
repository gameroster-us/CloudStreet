class CreateTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :tasks, id: :uuid  do |t|
      t.string :title
      t.string :description
      t.uuid :created_by
      t.uuid :account_id
      t.boolean :repeat, default: false
      t.datetime :start_datetime, :null => false
      t.json :end_schedule, :null => false
      t.integer :occurences_completed, default: 0
      t.json :data
      t.text :schedule, :null => false
      t.integer :task_type, :null => false
      t.boolean :notify, default: false
      t.json :notification_schedule

      t.timestamps
    end
  end
end
