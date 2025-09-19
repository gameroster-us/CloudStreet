class AddIndexToBusinessContextTag < ActiveRecord::Migration[5.2]
  def change
  	add_index :business_context_tags, :business_tag_key
    add_index :business_context_tags, :provider_tag_keys
    add_index :business_context_tags, [:business_tag_key, :provider_tag_keys], name: 'business_provider'
    add_index :business_context_tags, :account_id
  end
end
