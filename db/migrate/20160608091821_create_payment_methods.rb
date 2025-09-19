class CreatePaymentMethods < ActiveRecord::Migration[5.1]
  def change
    create_table :payment_methods, id: :uuid  do |t|
      t.uuid :user_id
      t.uuid :account_id
      t.uuid :payable_id
      t.string :payable_type

      t.timestamps
    end
  end
end
