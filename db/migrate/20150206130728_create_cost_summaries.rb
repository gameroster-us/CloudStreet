class CreateCostSummaries < ActiveRecord::Migration[5.1]
  def change
    create_table :cost_summaries, id: :uuid do |t|
      t.float :blended_cost
      t.float :unblended_cost
      t.date :date, index: true
      t.uuid :environment_id, index: true
      t.uuid :account_id, index: true
      t.uuid :adapter_id, index: true
      t.string :type, index: true

      t.timestamps
    end
  end
end
