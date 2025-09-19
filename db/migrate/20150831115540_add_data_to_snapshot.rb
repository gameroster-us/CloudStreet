class AddDataToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :data, :json
    add_column :snapshots, :error_message, :text
  end
end
