class AddPurposeToAdapter < ActiveRecord::Migration[5.1]
  def change
    add_column :adapters, :adapter_purpose, :string, default: "normal"
  end
end
