class AddMarginDiscountCalculationToAdapters < ActiveRecord::Migration[5.2]
  def change
    add_column :adapters, :margin_discount_calculation, :string
  end
end
