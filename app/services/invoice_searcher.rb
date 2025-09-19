class InvoiceSearcher < CloudStreetService
  def self.get_invoice_report(account, &block)
    invoices     = account.invoices.order('created_at DESC')

    status Status, :success, invoices, &block
    return invoices
  end
end
