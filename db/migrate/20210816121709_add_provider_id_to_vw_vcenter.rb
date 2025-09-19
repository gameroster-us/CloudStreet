class AddProviderIdToVwVcenter < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_vcenters, :provider_id, :string
    VwVcenter.where(provider_id: nil).update_all('provider_id = id')
  end
end
