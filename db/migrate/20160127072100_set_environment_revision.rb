class SetEnvironmentRevision < ActiveRecord::Migration[5.1]
  def change
  	remove_column :environments, :revision
  	add_column :environments, :revision, :float, default: 1.00
  end
end
