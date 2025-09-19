class CreateFilerConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :filer_configurations, id: :uuid  do |t|
      t.uuid :region_id, index: true
      t.uuid :adapter_id, index: true
      t.uuid :account_id, index: true
      t.uuid :security_group_id, index: true
      t.uuid :vpc_id, index: true
      t.uuid :filer_id, index: true
      t.string :protocol
      t.string :name
      t.string :type

      t.timestamps
    end
  end
end
