class AddColumnToTenant < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :tags, :json, default: {}
  end
end
