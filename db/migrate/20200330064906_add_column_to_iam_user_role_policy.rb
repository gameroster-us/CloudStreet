class AddColumnToIamUserRolePolicy < ActiveRecord::Migration[5.1]
  def change
    add_column :iam_user_role_policies , :aws_account_id, :string
  end
end
