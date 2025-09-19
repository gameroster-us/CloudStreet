class AddIsBillingToAdapters < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :is_billing, :boolean, default: false
  end
end
