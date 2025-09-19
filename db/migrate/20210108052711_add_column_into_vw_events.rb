# frozen_string_literal: true

class AddColumnIntoVwEvents < ActiveRecord::Migration[5.1]
  def change
    add_column :vw_events, :status, :integer, default: 0
    add_column :vw_events, :error, :string
    remove_column :vw_events, :completed, :boolean
  end
end
