class AddAzureResourceGroupToAzureResource < ActiveRecord::Migration[5.1]
  def change
    add_reference :azure_resources, :azure_resource_group, type: :uuid, foreign_key: true
    add_column :azure_resources, :state, :string
  end
end
