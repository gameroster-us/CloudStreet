class AddColumnToServiceTable < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :ignored_from, :string, default: "un-ignored"
  end
end
