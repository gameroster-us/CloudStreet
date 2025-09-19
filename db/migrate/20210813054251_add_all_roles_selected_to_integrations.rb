class AddAllRolesSelectedToIntegrations < ActiveRecord::Migration[5.1]
  def change
    add_column :integrations, :all_roles_selected, :boolean
  end
end
