class ChangeClusterEnvAndCluster < ActiveRecord::Migration[5.1]
  def change
    add_column :clusters, :environment_id, :uuid unless column_exists? :clusters, :environment_id
    drop_table :clusters_environment if ActiveRecord::Base.connection.table_exists? :clusters_environment
  end

end
