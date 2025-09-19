class AddAccountTagToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :account_tag, :string
  end
end
