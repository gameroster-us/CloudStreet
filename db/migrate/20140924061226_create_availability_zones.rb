class CreateAvailabilityZones < ActiveRecord::Migration[5.1]
  def change
    create_table :availability_zones , id: :uuid  do |t|
      t.string :zone_name
      t.uuid :region_id, index: true
      	
      t.timestamps
    end
  end
end
