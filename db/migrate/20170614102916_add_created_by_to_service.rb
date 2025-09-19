class AddCreatedByToService < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :created_by, :uuid
    add_index :services, :created_by
    add_foreign_key :services, :users, column: :created_by, primary_key: :id
  end
end
