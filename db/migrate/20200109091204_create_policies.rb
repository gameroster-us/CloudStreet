class CreatePolicies < ActiveRecord::Migration[5.1]
  def change
    create_table :policies, id: :uuid do |t|
      t.string :policy_name
      t.string :policy_arn
      t.string :type
      t.string :policy_id
      t.string :group_arn

      t.timestamps
    end
  end
end
