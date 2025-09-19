module InvoicesRepresenter
include Roar::JSON
include Roar::Hypermedia

  collection(
    :invoice,
    class: Invoice,
    extend: InvoiceRepresenter,
    embedded: false)

  def invoice
    collect
  end
end