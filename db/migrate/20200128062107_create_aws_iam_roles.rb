class CreateAWSIamRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :aws_iam_roles, id: :uuid do |t|
      
      t.string :aws_account_id
      t.string :role_name
      t.string :path
      t.string :role_id
      t.string :arn
      t.datetime :create_date
      t.json :assume_role_policy_document
      t.string :description
      t.integer :max_session_duration
      t.json :permissions_boundary
      t.json :tags 
      t.json :role_last_used
      t.json :role_trust_policy
      t.json :role_policy_details

      t.timestamps
    end
  end
end