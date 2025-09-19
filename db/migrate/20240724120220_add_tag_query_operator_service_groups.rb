class AddTagQueryOperatorServiceGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :service_groups, :tag_query_operator, :string
  end
end
