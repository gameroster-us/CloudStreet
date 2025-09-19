class CreateClusters < ActiveRecord::Migration[5.1]
  def change

    #Cluster Table
    create_table :clusters, id: :uuid do |t|
      t.json :data
      t.json :provider_data
      t.text :error_message
      t.string :state
      t.string :provider_id
      t.boolean :archived, :default => false
      t.string :type
      t.uuid :account_id
      t.uuid :region_id

      t.timestamps
    end

    #habtm association cluster and environment
    create_table :clusters_environments, id: :uuid do |t|
      t.uuid :environment_id
      t.uuid :cluster_id
    end
      #indexing the columns
     add_index :clusters_environments, :environment_id
     add_index :clusters_environments, :cluster_id
  end
end
