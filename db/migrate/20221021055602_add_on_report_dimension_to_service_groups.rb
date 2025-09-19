class AddOnReportDimensionToServiceGroups < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :on_report_dimension, :jsonb, default: {} unless column_exists?(:service_groups, :on_report_dimension)
  end
end
