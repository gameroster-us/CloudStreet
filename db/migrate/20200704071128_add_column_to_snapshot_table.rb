class AddColumnToSnapshotTable < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :ignored_from, :string, default: "un-ignored"
  end
end
