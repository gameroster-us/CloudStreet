class AddColumnsToExportReportActivityLogs < ActiveRecord::Migration[5.1]
  def change
    add_column :export_report_activity_logs, :provider, :string
  end
end
