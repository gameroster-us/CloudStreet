class ModifyAzureVmPriceListsToAzurePriceLists < ActiveRecord::Migration[5.1]
  def change
    rename_table :azure_vm_price_lists, :azure_price_lists
    add_column   :azure_price_lists , :region_code, :string
    add_column   :azure_price_lists , :resource_type, :string
  end
end
