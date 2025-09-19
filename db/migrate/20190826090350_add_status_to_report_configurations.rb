class AddStatusToReportConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :report_configurations, :status, :boolean, default: true
  end
end
