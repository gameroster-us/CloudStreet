class AddDataToSubnets < ActiveRecord::Migration[5.1]
  def up
    add_column :subnets, :data, :json
	end

	def down    
    remove_column :subnets, :data
  end
end
