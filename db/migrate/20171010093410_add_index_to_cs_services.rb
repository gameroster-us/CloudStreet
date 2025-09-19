class AddIndexToCSServices < ActiveRecord::Migration[5.1]
  def up
  	claen_orphan
  	add_index :CS_services, :id unless index_exists?(:CS_services, :id)
  	add_index :associated_services, :associated_CS_service_id unless index_exists?(:associated_services, :associated_CS_service_id)
   	add_foreign_key(:associated_services, :CS_services, column: :associated_CS_service_id, primary_key: :id, on_delete: :cascade)
  	# add_foreign_key(:filer_volumes, :CS_services, column: :CS_service_id)
  end

  def down
  	remove_index :CS_services, :id if index_exists?(:CS_services, :id)
  	remove_index :associated_services, :associated_CS_service_id if index_exists?(:associated_services, :associated_CS_service_id)
  	remove_foreign_key(:associated_services, column: :associated_CS_service_id)
  	# remove_foreign_key(:filer_volumes, column: :CS_service_id)
  end

  def claen_orphan
  	CS_ids = CSService.all.pluck(:id)
  	AssociatedService.where.not(associated_CS_service_id: CS_ids).delete_all
  end
end
