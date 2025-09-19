class AddExecutorIdToSynchronizations < ActiveRecord::Migration[5.1]
  def change
    add_column :synchronizations, :executor_id, :uuid
  end
end
