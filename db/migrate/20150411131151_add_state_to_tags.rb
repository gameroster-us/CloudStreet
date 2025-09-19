class AddStateToTags < ActiveRecord::Migration[5.1]
  def change
    add_column :tags, :state, :string
  end
end
