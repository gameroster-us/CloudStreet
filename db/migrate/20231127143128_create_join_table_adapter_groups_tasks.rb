class CreateJoinTableAdapterGroupsTasks < ActiveRecord::Migration[5.2]
  def change
    create_table :adapter_groups_tasks, id: false do |t|
      t.uuid :adapter_group_id, foreign_key: { to_table: 'service_groups' }
      t.uuid :task_id
      t.boolean :tenant_access, default: true
    end
  end
end
