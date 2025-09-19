class AddCreatedByToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :created_by, :uuid
    add_index :snapshots, :created_by
    add_foreign_key :snapshots, :users, column: :created_by, primary_key: :id
  end
end
