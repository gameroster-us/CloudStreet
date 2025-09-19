class AddTenantToPurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    add_reference :purchase_orders, :tenant, type: :uuid, foreign_key: true
  end
end
