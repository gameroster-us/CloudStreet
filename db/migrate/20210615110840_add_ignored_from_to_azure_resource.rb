class AddIgnoredFromToAzureResource < ActiveRecord::Migration[5.1]
  def change
    add_column :azure_resources, :ignored_from, :string, array: true, default: ['un-ignored'], null: false
  end
end
