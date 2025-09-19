class CreateAzureVmPriceList < ActiveRecord::Migration[5.1]
  def change
    create_table :azure_vm_price_lists, id: :uuid do |t|
      t.uuid :subscription_id, :unique => true
      t.json :sku_details, default: []
      t.timestamps
    end
  end
end
