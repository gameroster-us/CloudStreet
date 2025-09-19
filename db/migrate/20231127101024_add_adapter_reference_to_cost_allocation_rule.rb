class AddAdapterReferenceToCostAllocationRule < ActiveRecord::Migration[5.2]
  def change
  	add_reference :cost_allocation_rules, :adapter, type: :uuid, foreign_key: true
  end
end
