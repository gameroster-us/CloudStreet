class RenameInstanceFilersToFilerVolumes < ActiveRecord::Migration[5.1]
  def change
     rename_table :instance_filers, :filer_volumes
  end
end
