class InvoicesController < ApplicationController

  def download_invoice
    @invoice = Invoice.find params[:id]
    @account = Account.find params[:account_id]
    pdf_name = "invoice_#{@invoice.created_at.strftime('%B-%Y')}_#{DateTime.now.to_i}.pdf"

    file_path = @invoice.create_invoice_pdf(@account, pdf_name)

    render json: { message: "Not Found" }, status: 404 and return unless File.exist?(file_path)
    system "sudo touch #{file_path} && sudo chown cloudstreet:cloudstreet #{file_path}"
    File.open(file_path, 'r') do |f|
      send_data f.read, :filename => pdf_name, :type => "application/pdf", :disposition => "attachment"
    end
    system "sudo rm #{file_path}"
  end

end
