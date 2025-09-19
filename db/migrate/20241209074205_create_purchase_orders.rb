class CreatePurchaseOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :purchase_orders, id: :uuid do |t|

      t.string :name, null: false
      t.string :description, null: false
      t.string :provider_type, null: false
      t.string :status, default: 'active'
      t.uuid :billing_adapter_id, null: false
      t.date :start_date, null: false
      t.date :end_date
      t.float :po_amount, default: 0.0
      t.float :final_po_balance, default: 0.0
      t.float :alert_percentage, default: 10.0
      t.jsonb :adapter_groups, array: true, default: []
      t.string :customer_tags, array: true, default: []
      t.jsonb :accounts, array: true, default: []
      t.jsonb :subscriptions, array: true, default: []
      t.jsonb :services, array: true, default: []
      t.boolean :notify, default: false
      t.string :notify_to, array: true, default: []
      t.string :custom_emails, array: true, default: []
      t.boolean :is_all_services_selected, default: false
      t.string :type

      t.timestamps
    end

    add_index :purchase_orders, :billing_adapter_id
    add_index :purchase_orders, :provider_type
    add_index :purchase_orders, :name, unique: true
  end
end
