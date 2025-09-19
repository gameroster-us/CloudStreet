class CreateAzureCostSummaries < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_cost_summaries, id: :uuid do |t|
      t.decimal :hourly_cost, :precision => 23, :scale => 18, default: 0.0
      t.decimal :usage_cost, :precision => 23, :scale => 18, default: 0.0
      t.uuid :CS_service_id
      t.json :summary

      t.timestamps
    end
    add_foreign_key(:azure_cost_summaries, :CS_services, column: 'CS_service_id', on_delete: :cascade)
  end
end