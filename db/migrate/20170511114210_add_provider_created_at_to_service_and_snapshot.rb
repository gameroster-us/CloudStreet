class AddProviderCreatedAtToServiceAndSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :provider_created_at, :datetime
    add_column :snapshots, :provider_created_at, :datetime
  end
end
