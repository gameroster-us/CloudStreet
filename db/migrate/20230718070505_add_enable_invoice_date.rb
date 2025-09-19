class AddEnableInvoiceDate < ActiveRecord::Migration[5.2]
  def change
    add_column :adapters, :enable_invoice_date, :boolean, default: false
  end
end
