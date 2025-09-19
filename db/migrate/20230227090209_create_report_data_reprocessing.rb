class CreateReportDataReprocessing < ActiveRecord::Migration[5.1]
  def change
    create_table :report_data_reprocessings, id: :uuid do |t|
      t.uuid :adapter_id, index: true
      t.uuid :user_id
      t.string :reprocessing_month
      t.string :provider_type
      t.datetime :start_time
      t.datetime :end_time
      t.integer :status
      t.string :error_logs
      t.timestamps
    end
  end
end
