class CreateIamRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :iam_roles, id: :uuid do |t|
      t.string :aws_account_id
    	t.string :role
    	t.string :arn
    	t.string :instance_profile_id
      t.timestamps
    end
  end
end
