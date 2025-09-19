# frozen_string_literal: true

class CreateVwVdcs < ActiveRecord::Migration[5.1]
  def change
    create_table :vw_vdcs, id: :uuid do |t|
      t.string :name
      t.uuid :account_id
      t.timestamps
    end
  end
end
