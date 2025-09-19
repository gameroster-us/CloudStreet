class AddSynchronizedFieldToService < ActiveRecord::Migration[5.1]
  def change
    add_column :services, :synchronized, :boolean
  end
end
