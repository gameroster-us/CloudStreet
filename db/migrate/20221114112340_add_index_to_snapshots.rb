class AddIndexToSnapshots < ActiveRecord::Migration[5.1]
  def change
    add_index :snapshots, ['adapter_id', 'region_id']
  end
end
