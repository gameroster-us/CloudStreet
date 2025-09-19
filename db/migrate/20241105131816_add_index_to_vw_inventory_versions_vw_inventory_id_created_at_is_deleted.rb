class AddIndexToVwInventoryVersionsVwInventoryIdCreatedAtIsDeleted < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :vw_inventory_versions, 
             [:vw_inventory_id, :created_at, :is_deleted], 
	         algorithm: :concurrently,
             name: 'idx_inventory_versions_on_id_created_deleted', 
             order: { created_at: :desc },
             using: :btree unless index_exists?(:vw_inventory_versions, [:vw_inventory_id, :created_at, :is_deleted])
  end
end
