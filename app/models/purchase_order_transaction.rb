class PurchaseOrderTransaction < ApplicationRecord
  validates :type, :transaction_amount, :transaction_date, presence: true
  validates :transaction_amount, numericality: { greater_than_or_equal_to: 0 }
  belongs_to :purchase_order

  scope :credits, -> { where(type: "PurchaseOrderTransactions::PurchaseOrderCredit") }
  scope :debits, -> { where(type: "PurchaseOrderTransactions::PurchaseOrderDebit") }
end
