class CreateGCPReportConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :gcp_report_configurations, id: :uuid do |t|
      t.boolean :status, default: true
      t.uuid :adapter_id
      t.text :error_message, array: true, default: []

      t.timestamps
    end
    add_foreign_key :gcp_report_configurations, :adapters, on_delete: :cascade
    add_index :gcp_report_configurations, :adapter_id        
  end
end
