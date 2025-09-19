class AddIsDefaultToTenant < ActiveRecord::Migration[5.1]
  def change
    add_column :tenants, :is_default, :boolean , default: false
  end
end
