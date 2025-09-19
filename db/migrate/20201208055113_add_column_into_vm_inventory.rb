# frozen_string_literal: true

class AddColumnIntoVmInventory < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_inventories, :idle_instance, :boolean, default: false
  end
end
