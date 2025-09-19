class ChangeSnapshotIgnoredFromToArray < ActiveRecord::Migration[5.1]
  def change
  	remove_column :snapshots, :ignored_from, :string
  	add_column :snapshots, :ignored_from, :string,  array: true, default: ["un-ignored"], null:false
  end
end
