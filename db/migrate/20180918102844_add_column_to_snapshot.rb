class AddColumnToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :publicly_accessible, :boolean, default: false
  end
end
