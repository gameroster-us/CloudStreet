class AddInvoiceDateToAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :invoice_date, :string
  end
end
