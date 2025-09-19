class AddRegionIdToResources < ActiveRecord::Migration[5.1]
  def change
  	add_column :resources, :region_id, :uuid
  	add_column :resources, :adapter_id, :uuid
  end
end
