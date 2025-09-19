class AddExcludeEdpToTenants < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :exclude_edp, :boolean
  end
end
