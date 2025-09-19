class CreatePurchaseOrderTransactions < ActiveRecord::Migration[5.2]
  def change
    create_table :purchase_order_transactions, id: :uuid do |t|
      t.references :purchase_order, type: :uuid, foreign_key: true
      t.float :transaction_amount, default: 0.0
      t.float :po_balance, default: 0.0
      t.string :type, null: false
      t.string :remarks
      t.date :transaction_date, null: false

      t.timestamps
    end

    add_index :purchase_order_transactions, :type
    add_index :purchase_order_transactions, :transaction_date
  end
end
