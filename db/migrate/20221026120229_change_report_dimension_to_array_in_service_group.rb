class ChangeReportDimensionToArrayInServiceGroup < ActiveRecord::Migration[5.1]
  def change
    remove_column :service_groups, :on_report_dimension, :jsonb, default: {}
    add_column :service_groups, :on_report_dimension, :json, array: true, default: []
  end
end
