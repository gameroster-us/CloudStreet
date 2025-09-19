class AddMachineImageIdToSnapshots < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :machine_image_id, :uuid
    add_index :snapshots, :machine_image_id
  end
end
