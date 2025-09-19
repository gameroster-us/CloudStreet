class AddPartialIndexToServices < ActiveRecord::Migration[5.2]
  def change
   add_index :services, [:adapter_id, :region_id, :type, :state], 
              where: "deleted_at IS NULL", 
              name: "idx_services_optimized"	
  end
end
