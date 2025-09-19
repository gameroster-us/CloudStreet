class AddInvoiceNumberToInvoices < ActiveRecord::Migration[5.1]
  def self.up
    add_column :invoices, :invoice_number, :serial
  end

  def self.down
    remove_column :invoices, :invoice_number
  end  
end
