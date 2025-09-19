class AddIndexToServicesStateTypeDeletedAtVpcId < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :services, [:deleted_at, :state, :type, :vpc_id], name: 'idx_services_deleted_at_state_type_vpc_id', where: "deleted_at IS NULL", algorithm: :concurrently

    add_index :services, :vpc_id, algorithm: :concurrently unless index_exists?(:services, :vpc_id)
  end
end
