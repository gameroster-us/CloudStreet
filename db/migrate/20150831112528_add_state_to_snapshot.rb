class AddStateToSnapshot < ActiveRecord::Migration[5.1]
  def change
    add_column :snapshots, :state, :string
  end
end
