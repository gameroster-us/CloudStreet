class AddIndexOnOrganisationColumns < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!
  def change
    add_index :organisations, :id, algorithm: :concurrently unless index_exists?(:organisations, :id)
    add_index :organisations, :is_active, algorithm: :concurrently unless index_exists?(:organisations, :is_active)
    add_index :organisations, :organisation_identifier, algorithm: :concurrently unless index_exists?(:organisations, :organisation_identifier)
    add_index :organisations, :subdomain, algorithm: :concurrently unless index_exists?(:organisations, :subdomain)
  end
end