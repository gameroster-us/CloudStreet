class AddStateToSecurityGroups < ActiveRecord::Migration[5.1]
  def up
    add_column :security_groups, :state, :string, :default => 'pending'
    add_column :security_groups, :data, :json
    execute "UPDATE security_groups SET state='available' where group_id IS NOT NULL"
	end

	def down
    remove_column :security_groups, :state
    remove_column :security_groups, :data
  end
end
