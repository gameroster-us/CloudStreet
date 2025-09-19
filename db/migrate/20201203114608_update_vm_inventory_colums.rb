# frozen_string_literal: true

class UpdateVmInventoryColums < ActiveRecord::Migration[5.1]
  def change
    rename_column :vw_inventories, :name, :provider_id
  end
end
