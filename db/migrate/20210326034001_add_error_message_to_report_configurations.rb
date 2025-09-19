class AddErrorMessageToReportConfigurations < ActiveRecord::Migration[5.1]
  def change
    add_column :report_configurations, :error_message, :text, array: true, default: []
  end
end
