class AddInternalFieldToConnections < ActiveRecord::Migration[5.1]
  def change
    add_column :connections, :internal, :boolean, default: false
  end
end
