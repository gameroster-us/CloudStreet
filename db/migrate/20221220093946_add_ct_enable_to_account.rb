class AddCtEnableToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :ct_enable, :boolean, default: true
  end
end
