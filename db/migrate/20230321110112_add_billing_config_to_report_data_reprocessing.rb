class AddBillingConfigToReportDataReprocessing < ActiveRecord::Migration[5.1]
  def change
    add_column :report_data_reprocessings, :billing_configs, :json, array: true, default: []
    add_column :report_data_reprocessings, :ri_sp_configs, :json, array: true, default: []
  end
end
