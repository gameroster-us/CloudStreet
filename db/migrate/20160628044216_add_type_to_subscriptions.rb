class AddTypeToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_column :subscriptions, :type, :string
  end
end
