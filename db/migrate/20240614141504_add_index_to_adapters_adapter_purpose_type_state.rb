class AddIndexToAdaptersAdapterPurposeTypeState < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :adapters, [:type, :adapter_purpose, :state], algorithm: :concurrently unless index_exists?(:adapters, [:type, :adapter_purpose, :state])
  end
end
