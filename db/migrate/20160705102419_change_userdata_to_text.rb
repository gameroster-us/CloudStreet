class ChangeUserdataToText < ActiveRecord::Migration[5.1]
  def up
    change_column :machine_image_configurations, :userdata, :text
	end
	def down	
    change_column :machine_image_configurations, :userdata, :string
	end
end
