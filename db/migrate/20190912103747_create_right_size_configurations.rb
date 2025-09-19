class CreateRightSizeConfigurations < ActiveRecord::Migration[5.1]
  def change
    create_table :right_size_configurations, id: :uuid do |t|
      t.uuid :account_id
      t.text :family_type, array: true, default: []
      t.boolean :right_size_config_check, default: false
      t.timestamps
    end
  end
end
