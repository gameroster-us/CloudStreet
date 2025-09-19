class AddForeignKeyDBCascadeToSubscriptions < ActiveRecord::Migration[5.1]
  def change
    add_foreign_key(:subscriptions, :adapters, column: 'adapter_id', on_delete: :cascade)
  end
end