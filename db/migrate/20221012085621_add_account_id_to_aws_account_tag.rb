class AddAccountIdToAWSAccountTag < ActiveRecord::Migration[5.1]
  def change
    add_column :aws_account_tags, :account_id, :uuid
  end
end
