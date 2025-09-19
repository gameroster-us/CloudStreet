class CreateBillingCurrency < ActiveRecord::Migration[5.1]
  def change
    create_table :billing_currencies, id: :uuid do |t|
      t.string :type
      t.string :currency
      t.string :symbol
      t.references :adapter, type: :uuid, foreign_key: true
    end
  end
end
