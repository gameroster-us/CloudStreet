class PurchaseOrderTransactions::PurchaseOrderCredit < PurchaseOrderTransaction
  validate :validate_credit_amount

  private

  def validate_credit_amount
    errors.add(:transaction_amount, "must be greater than zero") if amount <= 0
  end
end
