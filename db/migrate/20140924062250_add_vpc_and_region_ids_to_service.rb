class AddVpcAndRegionIdsToService < ActiveRecord::Migration[5.1]
  def change
  	add_column :services, :region_id, :uuid, index: true
  	add_column :services, :vpc_id, :uuid, index: true
  end
end
