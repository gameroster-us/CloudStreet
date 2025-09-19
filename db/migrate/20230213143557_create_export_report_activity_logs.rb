class CreateExportReportActivityLogs < ActiveRecord::Migration[5.1]
  def change
    create_table :export_report_activity_logs, id: :uuid do |t|
      t.references :organisation, type: :uuid, foreign_key: true
      t.references :account, type: :uuid, foreign_key: true
      t.references :user, type: :uuid, foreign_key: true
      t.references :tenant, type: :uuid, foreign_key: true
      t.string :report_type, default: 'sheet'
      t.string :filename
      t.string :status, default: 'processing'
      t.string :failed_reason

      t.timestamps
    end
  end
end
