class AddNotSupportedRegionsToAdapter < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :not_supported_regions, :string, array: true, default: [], null: false
  end
end
