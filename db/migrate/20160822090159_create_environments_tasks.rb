class CreateEnvironmentsTasks < ActiveRecord::Migration[5.1]
  def change
    create_table :environments_tasks do |t|
      t.uuid :environment_id
      t.uuid :task_id
    end
    add_index :environments_tasks, :environment_id
    add_index :environments_tasks, :task_id

    Task.where(task_type: [1,2,3]).find_in_batches do |group|
      group.each { |task|
        task.environment_ids= (Environment.where(id: task.attributes["data"]["environment_ids"]).pluck :id)
      }
    end
    Task.where(task_type: [4]).find_in_batches do |group|
      group.each { |task|
        ids = task.account.backup_policies.where(id: task.backup_policy_ids).pluck(:environment_ids).flatten.uniq.compact
        task.environment_ids= Environment.where(id: ids).pluck(:id)
      }
    end
  end
end
