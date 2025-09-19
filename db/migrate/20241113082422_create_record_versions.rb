class CreateRecordVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :record_versions, id: :uuid do |t|
      t.references :versionable, polymorphic: true, null: false, type: :uuid
      t.json :data_changes
      t.timestamps
    end

  end
end
