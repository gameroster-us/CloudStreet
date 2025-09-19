class AddSubnetIdToServices < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :provider_id, :string
  end
end
