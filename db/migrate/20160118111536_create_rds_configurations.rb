class CreateRdsConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :rds_configurations, id: :uuid do |t|
      t.uuid :account_id
      t.uuid :created_by
      t.uuid :updated_by
      t.json :data
      t.timestamps
    end
  end
end
