class CreateIamUserRolePolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :iam_user_role_policies, id: :uuid do |t|
      t.uuid :policy_id
      t.uuid :iam_id
      t.string :iam_type

      t.timestamps
    end
  end
end
