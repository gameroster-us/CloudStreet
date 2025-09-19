class RemoveSourceDestinationFromFilerInstances < ActiveRecord::Migration[5.1]
  def change
    remove_column :instance_filers, :source
    remove_column :instance_filers, :destination
  end
end
