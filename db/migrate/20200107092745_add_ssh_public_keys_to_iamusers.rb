class AddSshPublicKeysToIamusers < ActiveRecord::Migration[5.1]
  def change
  	add_column :iam_users, :adapter_id, :uuid
  	add_column :iam_users, :ssh_public_keys, :json
  	add_column :iam_users, :access_keys_list, :json
  	add_column :iam_users, :is_login_profile_present, :boolean
  	add_column :iam_users, :is_list_mfa_devices_present, :boolean
  end
end


