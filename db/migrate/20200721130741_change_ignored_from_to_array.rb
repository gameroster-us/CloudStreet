class ChangeIgnoredFromToArray < ActiveRecord::Migration[5.1]
  def change
  	remove_column :services, :ignored_from, :string
  	add_column :services, :ignored_from, :string,  array: true, default: ["un-ignored"], null:false
  end
end
