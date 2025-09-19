class AddIdleInstanceToAzureResource < ActiveRecord::Migration[5.1]

  def change
    add_column :azure_resources, :idle_instance, :boolean, default: false
  end

end
