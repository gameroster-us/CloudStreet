class AddSynchronizedFieldToVpc < ActiveRecord::Migration[5.1]
  def change
    add_column :vpcs, :synchronized, :boolean, :default => false
  end
end
