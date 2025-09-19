class AddRiSpSummaryDataToSummaryAdverSummary < ActiveRecord::Migration[5.2]
  def change
    add_column :service_adviser_summaries, :ri_sp_summary_data, :json
  end
end
