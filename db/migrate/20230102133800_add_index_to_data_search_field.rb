class AddIndexToDataSearchField < ActiveRecord::Migration[5.1]
  def self.up
    execute("CREATE INDEX index_data_subscription_id on adapters ((data->'subscription_id')) where type = 'Adapters::Azure'; ")
    execute("CREATE INDEX index_data_project_id on adapters ((data->'project_id')) where type = 'Adapters::GCP'; ")
    execute("CREATE INDEX index_data_aws_account_id on adapters ((data->'aws_account_id')) where type = 'Adapters::AWS'; ")
  end

  def self.down
    execute("DROP INDEX index_data_subscription_id")
    execute("DROP INDEX index_data_project_id")
    execute("DROP INDEX index_data_aws_account_id")
  end
end


