class AddVirtualMfaDevicesToIamUser < ActiveRecord::Migration[5.1]
  def change
  	add_column :iam_users, :virtual_mfa_devices, :json 
  end
end
