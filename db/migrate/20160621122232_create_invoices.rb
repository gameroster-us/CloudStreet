class CreateInvoices < ActiveRecord::Migration[5.1]
  def change
    create_table :invoices, id: :uuid  do |t|
      t.datetime :payment_due_date
      t.datetime :payment_date
      t.string :payment_status, default: 'pending'
      t.json :data
      t.uuid :account_id

      t.timestamps
    end
  end
end
