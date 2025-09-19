class AddEnableFieldToTask < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :enable, :boolean, :default => true
  end
end
