class DestroyTableSynchronization < ActiveRecord::Migration[5.1]
  def up
    drop_table :synchronizations
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
