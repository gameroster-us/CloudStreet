class AddForeignKeyDBCascadeToCSServiceTags < ActiveRecord::Migration[5.1]
  def up
    add_foreign_key(:CS_services_tag_key_values, :CS_services, column: 'CS_service_id', on_delete: :cascade)
    add_foreign_key(:tag_key_values, :tag_keys, column: 'tag_key_id', on_delete: :cascade)
  end

  def down
    remove_foreign_key(:CS_services_tag_key_values, name: 'CS_services_tag_key_values_CS_service_id_fk')
    remove_foreign_key(:tag_key_values, name: 'tag_key_values_tag_key_id_fk')
  end
end
