class CreateAssociatedServices < ActiveRecord::Migration[5.1]
  def change
    create_table :associated_services, id: :uuid do |t|
      t.string :name, null: false
      t.string :service_type, null: false
      t.uuid :associated_CS_service_id, null: false
      t.uuid :CS_service_id, null: false, index: true

      t.timestamps
    end
    add_index :associated_services, :CS_service_id
    add_foreign_key(:associated_services, :CS_services, column: 'CS_service_id', on_delete: :cascade)
  end
end
