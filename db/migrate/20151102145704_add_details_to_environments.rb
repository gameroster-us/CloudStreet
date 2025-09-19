class AddDetailsToEnvironments < ActiveRecord::Migration[5.1]
  def change
    add_column :environments, :user_role_ids, :uuid, array: true, default: [], :null => false
    add_column :environments, :data, :json, default: {}
  end
end
