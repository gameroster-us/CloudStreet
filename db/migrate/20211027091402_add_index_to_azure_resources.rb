class AddIndexToAzureResources < ActiveRecord::Migration[5.1]
  def change
  	add_index('azure_resources', [:cost_by_hour], order: { cost_by_hour: :desc })
  end
end
