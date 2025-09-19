class AddTypeToVpcs < ActiveRecord::Migration[5.1]
  def change
    add_column :vpcs, :type, :string
    add_column :vpcs, :adapter_id, :uuid, index: true
  end
end
