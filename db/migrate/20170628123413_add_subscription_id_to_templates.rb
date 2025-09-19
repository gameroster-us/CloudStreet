class AddSubscriptionIdToTemplates < ActiveRecord::Migration[5.1]
  def change
    add_column :templates, :subscription_id, :uuid

    add_index :templates, :subscription_id
  end
end
