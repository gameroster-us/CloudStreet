class AddCloudProviderNameToFiler < ActiveRecord::Migration[5.1]
  def change
    add_column :filers, :cloud_provider_name, :string
  end
end
