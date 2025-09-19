# frozen_string_literal: true

# Use to store business context tags
class CreateBusinessContextTags < ActiveRecord::Migration[5.1]
  def change
    create_table :business_context_tags, id: :uuid, comment: 'Use for cost allocation' do |t|
      t.string :business_tag_key
      t.text :provider_tag_keys, array: true, default: []
      t.text :description
      t.uuid :account_id

      t.timestamps
    end
  end
end
