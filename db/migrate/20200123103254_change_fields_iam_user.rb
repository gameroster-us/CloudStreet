class ChangeFieldsIamUser < ActiveRecord::Migration[5.1]
  def change
  	remove_column :iam_users, :is_login_profile_present, :boolean
  	remove_column :iam_users, :is_list_mfa_devices_present, :boolean
  	add_column :iam_users, :login_profile, :json
  	add_column :iam_users, :list_mfa_devices, :json
  end
end
