class AddServiceTypeColumnInTaskTable < ActiveRecord::Migration[5.1]
  def change
  	add_column :tasks, :service_type, :string, default: [], array: true
  end
end
