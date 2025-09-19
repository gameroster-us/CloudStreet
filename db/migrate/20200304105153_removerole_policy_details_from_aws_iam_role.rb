class RemoverolePolicyDetailsFromAWSIamRole < ActiveRecord::Migration[5.1]
  def change
  	remove_column :aws_iam_roles, :role_policy_details, :json
  end
end
