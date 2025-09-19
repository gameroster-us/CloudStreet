class ChangeServiceTypesDiscountTypeFromAdapters < ActiveRecord::Migration[5.1]
  def change
    change_column :adapters, :service_types_discount, :jsonb, default: {}
  end
end
