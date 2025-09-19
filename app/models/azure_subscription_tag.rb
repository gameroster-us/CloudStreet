# frozen_string_literal: true

class AzureSubscriptionTag < ApplicationRecord

  belongs_to :account
  scope :azure_subscription_by_tag_value, ->(tag_value) { where("array_to_json(tags)::jsonb @>?", [{"value"=>tag_value.downcase}].to_json) }

  def fetch_tag_value(tag_key)
    tags.find { |tag| tag['key'].eql?(tag_key) }.try('[]', 'value').try(:downcase)
  end

end
