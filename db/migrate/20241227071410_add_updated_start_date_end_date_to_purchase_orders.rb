class AddUpdatedStartDateEndDateToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :purchase_orders, :updated_start_date, :date
    add_column :purchase_orders, :updated_end_date, :date
  end
end
