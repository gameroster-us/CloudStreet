# frozen_string_literal: true

class CreateVwEvents < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_events, id: :uuid do |t|
      t.integer :count
      t.integer :size
      t.integer :cores_per_socket
      t.boolean :forceful_apply, default: false
      t.boolean :completed, default: false
      t.integer :name, default: 0
      t.belongs_to(:vw_inventory, foreign_key: true, type: :uuid)
      t.timestamps
    end
  end
end
