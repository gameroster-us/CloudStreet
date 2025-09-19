class SetServiceDefaultTagsToEmptyHash < ActiveRecord::Migration[5.1]
  def change
    change_column :nacls, :tags, :json, :default => '{}'
    change_column :nacls, :associations, :json, :default => '{}'
    change_column :nacls, :entries, :json, :default => '{}'
    change_column :route_tables, :tags, :json, :default => '{}'
    change_column :subnets, :tags, :json, :default => '{}'
  end
end
