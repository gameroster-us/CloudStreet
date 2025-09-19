class AddSourceDestinationToInstanceFilers < ActiveRecord::Migration[5.1]
  def change
    add_column :instance_filers, :source, :string
    add_column :instance_filers, :destination, :string
  end
end
