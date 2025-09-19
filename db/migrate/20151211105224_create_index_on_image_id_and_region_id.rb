class CreateIndexOnImageIdAndRegionId < ActiveRecord::Migration[5.1]
  def change
	add_index :machine_images, ["image_id", "region_id"], :unique => true
  end
end
