class CreateWorkspaces < ActiveRecord::Migration[5.1]
  def change
    create_table :workspaces, id: :uuid do |t|
      t.string :name
      t.string :type
      t.uuid :user_id
      t.uuid :account_id
      t.uuid :organisation_id
      t.jsonb :data, default: {}
      t.string :state, default: "Active"
      
      t.timestamps
    end

    add_index :workspaces, :user_id
    add_index :workspaces, :organisation_id
    add_index :workspaces, :data, using: :gin
  end
end
