class CreateIntegrations < ActiveRecord::Migration[5.1]
  def change
    create_table :integrations, id: :uuid do |t|
      t.string :name
      t.uuid :user_id
      t.uuid :account_id
      t.uuid :workspace_id
      t.uuid :organisation_id
      t.jsonb :data, default: {}
      t.text :slack_members, array: true, default: []
      t.text :modules, array: true, default: []
      t.string :type
      t.integer :state, default: 0
      t.boolean :is_mute, default: false
      t.timestamps
    end

    add_index :integrations, :user_id
    add_index :integrations, :workspace_id
    add_index :integrations, :slack_members, using: 'gin'
  end
end
