class AddFirstSnaphotToSnapshots < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :first_snapshot, :boolean, default: false
  end
end
