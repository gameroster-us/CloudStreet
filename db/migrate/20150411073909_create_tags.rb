class CreateTags < ActiveRecord::Migration[5.1]
  def change
    create_table :tags, id: :uuid  do |t|
      t.string :tag_key
      t.string :tag_type
      t.string :tag_value,array: true, default: '{}'
      t.boolean :is_mandatory
      t.hstore :data
      t.uuid :account_id
      t.uuid :created_by
      t.uuid :updated_by
      t.timestamps
    end
  end
end
