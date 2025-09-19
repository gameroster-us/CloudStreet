class AddAclPropretiesToStorages < ActiveRecord::Migration[5.1]
  def change
    add_column :storages, :owner_id, :string
    add_column :storages, :owner_display_name, :string
    add_column :storages, :access_control_list, :json
  end
end
