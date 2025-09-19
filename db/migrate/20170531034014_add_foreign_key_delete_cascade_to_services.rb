class AddForeignKeyDeleteCascadeToServices < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key(:interfaces, name: 'interfaces_service_id_fk')
    add_foreign_key(:interfaces, :services, column: 'service_id', on_delete: :cascade)
    remove_foreign_key(:connections, name: 'connections_interface_id_fk')
    add_foreign_key(:connections, :interfaces, column: 'interface_id', on_delete: :cascade)
    remove_foreign_key(:connections, name: 'connections_remote_interface_id_fk')
    add_foreign_key(:connections, :interfaces, column: 'remote_interface_id', on_delete: :cascade)
  end

  def down
  end
end
