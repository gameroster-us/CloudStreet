class AddIndexToAzurePriceLists < ActiveRecord::Migration[5.2]
  def change
    add_index :azure_price_lists, [:id, :subscription_id], unique: false, name: 'index_azure_price_lists_id_subscription_id'
  end
end
