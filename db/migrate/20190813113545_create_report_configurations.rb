class CreateReportConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :report_configurations, id: :uuid do |t|
      t.string :report_name
      t.string :report_prefix
      t.string :compression_type
      t.uuid   :adapter_id

      t.timestamps
    end
    add_foreign_key :report_configurations, :adapters, on_delete: :cascade
    add_index :report_configurations, :adapter_id
  end
end
