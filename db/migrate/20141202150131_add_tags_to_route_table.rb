class AddTagsToRouteTable < ActiveRecord::Migration[5.1]
  def change
    add_column :route_tables, :tags, :json
  end
end
