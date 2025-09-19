class AddGroupBasedOnAccountTagToServiceGroup < ActiveRecord::Migration[5.1]
  def change
    add_column :service_groups, :group_based_on_account_tag, :boolean, default: false
  end
end
