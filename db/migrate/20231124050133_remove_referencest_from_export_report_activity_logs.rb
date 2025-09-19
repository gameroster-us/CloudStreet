class RemoveReferencestFromExportReportActivityLogs < ActiveRecord::Migration[5.2]
  def change
    remove_reference :export_report_activity_logs, :account, foreign_key: true
    remove_reference :export_report_activity_logs, :user, foreign_key: true
    add_column :export_report_activity_logs, :user_id, :string
  end
end
