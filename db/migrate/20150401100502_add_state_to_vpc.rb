class AddStateToVpc < ActiveRecord::Migration[5.1]
  def change
    add_column :vpcs, :state, :string
  end
end
