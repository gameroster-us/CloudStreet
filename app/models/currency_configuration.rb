class CurrencyConfiguration < ApplicationRecord
  belongs_to :organisation
  validates_presence_of :default_currency, :cloud_provider_currency
  validates_uniqueness_of :organisation_id, :scope => [:default_currency, :cloud_provider_currency], message: 'Duplicate Currency Configuration'
  HUMANIZED_ATTRIBUTES = {
    organisation_id: ""
  }
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  scope :aws, -> { where(provider: 'AWS') }
  scope :azure, -> { where(provider: 'Azure') }
  scope :gcp, -> { where(provider: 'GCP') }

end