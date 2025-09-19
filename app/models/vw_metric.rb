# frozen_string_literal: true

# Model to store VMware metrics data
class VwMetric < ApplicationRecord
  belongs_to :vw_inventory

  scope :last_week, -> { where('noted_at > ?', 7.days.ago) }
  scope :last_month, -> { where('noted_at > ?', 30.days.ago) }
end