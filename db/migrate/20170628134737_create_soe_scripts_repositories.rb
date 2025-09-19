class CreateSoeScriptsRepositories < ActiveRecord::Migration[5.1]
  def change
    create_table :soe_scripts_remote_sources, id: :uuid do |t|
      t.text :url, index: true, unique: true, not_null: true
      t.datetime :last_updated, not_null: true
      t.string :version, not_null: true
      t.string :state, not_null: true, default: "active"

      t.timestamps
    end
  end
end
