class CreateBudgetAccounts < ActiveRecord::Migration[5.1]
  def change
    create_table :budget_accounts, id: :uuid do |t|
      t.string :provider_account_id
      t.string :provider_account_name
      t.references :budget, type: :uuid, foreign_key: true
      t.timestamps
    end
  end
end
