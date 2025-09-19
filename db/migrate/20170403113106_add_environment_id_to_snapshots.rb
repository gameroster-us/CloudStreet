class AddEnvironmentIdToSnapshots < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :environment_id, :uuid
  end
end
