class AddStateToSubnet < ActiveRecord::Migration[5.1]
  def up
    add_column :subnets, :state, :string, :default => 'pending'
    execute "UPDATE subnets SET state='available' where provider_id IS NOT NULL"
	end

	def down
    remove_column :subnets, :state
	end
end
