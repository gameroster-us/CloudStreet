class AddIndexToCost < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!
  
  def up
 	add_index :costs, :adapter_id, algorithm: :concurrently unless index_exists?(:costs, :adapter_id)
 	add_index :cost_summaries, :adapter_id, algorithm: :concurrently unless index_exists?(:cost_summaries, :adapter_id)
  end

  def down
 	remove_index :costs, :adapter_id if index_exists?(:costs, :adapter_id)
 	remove_index :cost_summaries, :adapter_id if index_exists?(:cost_summaries, :adapter_id)
  end
  
end
