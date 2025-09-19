class AddHistoricalTagToAWSAccountTags < ActiveRecord::Migration[5.2]
  def change
    add_column :aws_account_tags, :historical_tags, :jsonb, default: []
  end
end
