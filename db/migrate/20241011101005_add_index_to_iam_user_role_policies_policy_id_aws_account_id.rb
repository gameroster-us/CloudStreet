class AddIndexToIamUserRolePoliciesPolicyIdAWSAccountId < ActiveRecord::Migration[5.2]
   disable_ddl_transaction!

    def change
      add_index :iam_user_role_policies, [:policy_id, :aws_account_id], algorithm: :concurrently, name: 'index_policy_id_aws_account_id', using: :btree unless index_exists?(:iam_user_role_policies, [:policy_id, :aws_account_id])
  end
end
