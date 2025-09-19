# frozen_string_literal: true

# Model to store VMware vcenter record
class VwVcenter < ApplicationRecord
  has_many :vw_inventories, dependent: :destroy
  has_many :vw_events, through: :vw_inventories
  belongs_to :adapter, class_name: 'Adapters::VmWare'
  store_accessor :data, :name, :fqdn
  # fqdn => fully qualified domain name

  def organisation_identifier
    @organisation_identifier ||= adapter.account.organisation.try(:organisation_identifier)
  end

  def athena_table_name
    "#{ATHENA_METRIC_DATABASE}.#{organisation_identifier + '_vcenter_' + id.split('-').last}"
  end

  def provider_name
    self.fqdn ||  "#{self&.name} (#{self&.provider_id})"
  end
end
