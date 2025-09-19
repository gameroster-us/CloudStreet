class CreateIamGroups < ActiveRecord::Migration[5.1]
  def change
    create_table :iam_groups, id: :uuid do |t|
      t.uuid   :adapter_id
      t.uuid   :account_id
      t.string :group_id
      t.string :arn
      t.string :group_name
      t.string :create_date
      t.string :aws_account_id
      t.string :path
      t.json   :users

      t.timestamps
    end
  end
end