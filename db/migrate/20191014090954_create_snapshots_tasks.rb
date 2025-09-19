class CreateSnapshotsTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :snapshots_tasks, id: :uuid do |t|
      t.uuid :snapshot_id
      t.uuid :task_id

      t.timestamps
    end
    add_index :snapshots_tasks, :snapshot_id
    add_index :snapshots_tasks, :task_id
  end
end
