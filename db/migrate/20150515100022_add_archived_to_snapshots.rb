class AddArchivedToSnapshots < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :archived, :boolean, :default => false
  end
end
