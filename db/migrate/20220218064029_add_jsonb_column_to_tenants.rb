class AddJsonbColumnToTenants < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :all_selected_flags, :jsonb, default: {}
  end
end
