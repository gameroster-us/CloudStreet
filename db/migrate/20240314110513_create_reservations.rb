class CreateReservations < ActiveRecord::Migration[5.2]
  def change
    create_table :reservations, id: :uuid do |t|
      t.references :adapter, foreign_key: true, type: :uuid
      t.string :name
      t.string :reservation_id
      t.string :reservation_order_id
      t.date :expiration_date
      t.date :purchase_date
      t.string :product_name
      t.string :region
      t.integer :quantity
      t.float :last_day_utilization
      t.float :seven_days_utilization
      t.float :thirty_days_utilization
      t.boolean :archived
      t.string :scope_name
      t.string :scope_type
      t.string :term
      t.string :renewal
      t.string :status
      t.string :type
      t.string :reservation_type
      t.string :applied_scopes
      t.jsonb :tags, default:{}
      t.references :tag_key, type: :uuid, foreign_key: {to_table: :tags}

      t.timestamps
    end
  end
end
