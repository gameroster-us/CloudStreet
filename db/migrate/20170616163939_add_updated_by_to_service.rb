class AddUpdatedByToService < ActiveRecord::Migration[5.1]
  def change
  	add_column :services, :updated_by, :uuid
    add_index :services, :updated_by
    add_foreign_key :services, :users, column: :updated_by, primary_key: :id
  end
end
