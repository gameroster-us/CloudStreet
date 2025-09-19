class AddTypeToNetAppInstanceFilers < ActiveRecord::Migration[5.1]
  def change
    add_column :instance_filers, :type, :string
  end
end
