class AddIndexToIamRoles < ActiveRecord::Migration[5.1]
  def change
    add_index :iam_roles, [:aws_account_id, :role], :unique => true
  end
end
