class AddTriggeredAtToReportDataReprocessing < ActiveRecord::Migration[5.1]
  def change
    add_column :report_data_reprocessings, :triggered_at, :datetime
  end
end
