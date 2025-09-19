class CreateEnvironmentTags < ActiveRecord::Migration[5.1]
  def change
    create_table :environment_tags, id: :uuid  do |t|
      t.uuid :environment_id
      t.string :tag_key
      t.string :tag_type
      t.string :tag_value
      t.boolean :is_mandatory
      t.uuid :account_id
      t.uuid :created_by
      t.uuid :updated_by
      t.timestamps
    end
  end
end
