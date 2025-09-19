class AddForeignKeyToCost < ActiveRecord::Migration[5.1]
  def up
  	claen_orphan
  	add_foreign_key :costs, :adapters, on_delete: :cascade
    add_foreign_key :cost_summaries, :adapters, on_delete: :cascade
  end

  def down
  	remove_foreign_key :costs, :adapters
    remove_foreign_key :cost_summaries, :adapters
  end

  def claen_orphan
  	Cost.joins('LEFT JOIN adapters ON costs.adapter_id = adapters.id').where('adapters.id IS NULL').delete_all
  	CostSummary.joins('LEFT JOIN adapters ON cost_summaries.adapter_id = adapters.id').where('adapters.id IS NULL').delete_all
  end
end
