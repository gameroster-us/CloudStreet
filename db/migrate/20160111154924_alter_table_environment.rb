class AlterTableEnvironment < ActiveRecord::Migration[5.1]
  def change
  	remove_column :environments, :revision
  	add_column :environments, :revision, :float, :default => 0.00
  end
end
