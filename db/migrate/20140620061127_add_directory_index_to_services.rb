class AddDirectoryIndexToServices < ActiveRecord::Migration[5.1]
  def change
    add_index :services, :state
  end
end
