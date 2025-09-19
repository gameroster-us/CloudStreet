class AddColumnsToReportConfigurations < ActiveRecord::Migration[5.2]
  def change
    add_column :report_configurations, :role_arn, :string, default: nil
    add_column :report_configurations, :default_config, :boolean, default: true
    add_column :report_configurations, :bucket_name, :string, default: nil
    add_column :report_configurations, :bucket_region, :string, default: nil
  end
end
