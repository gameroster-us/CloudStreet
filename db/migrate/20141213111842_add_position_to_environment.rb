class AddPositionToEnvironment < ActiveRecord::Migration[5.1]
	def change
    add_column :environments, :position, :integer
  end
end