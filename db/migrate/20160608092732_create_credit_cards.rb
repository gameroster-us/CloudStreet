class CreateCreditCards < ActiveRecord::Migration[5.1]
  def change
    create_table :credit_cards, id: :uuid  do |t|
      t.string :card_holder
      t.string :card_number
      t.date :card_expiry
      t.string :token
      t.hstore :response_data

      t.timestamps
    end
  end
end
