class CreateServiceAdviserSummaries < ActiveRecord::Migration[5.1]
  def change
    create_table :service_adviser_summaries, id: :uuid do |t|
      t.uuid :account_id
      t.uuid :tenant_id
      t.string :tenant_name
      t.json :summary_data

      t.timestamps
    end
  end
end
