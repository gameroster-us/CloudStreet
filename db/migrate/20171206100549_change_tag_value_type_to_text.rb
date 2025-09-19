class ChangeTagValueTypeToText < ActiveRecord::Migration[5.1]
  def up
    change_column :tags, :tag_value, :text, array: true, default: []
  end
  
  def down
    change_column :tags, :tag_value, :string, array: true, default: []
  end
end
