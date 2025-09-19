class CreateRegions < ActiveRecord::Migration[5.1]
  def change
    create_table :regions , id: :uuid  do |t|
      t.string :region_name
      t.uuid :adapter_id, index: true
      
      t.timestamps
    end
  end
end