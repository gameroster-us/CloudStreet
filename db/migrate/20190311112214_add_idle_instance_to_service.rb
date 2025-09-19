class AddIdleInstanceToService < ActiveRecord::Migration[5.1]
  def change
  	add_column :services, :idle_instance, :boolean, default: false
  end
end
